module Net
  class IMAP
    class << self
      def recordings=(value)
        @replaying = !value.nil?
        @recordings = value
      end

      def recordings
        @recordings ||= {}
      end

      def replaying?
        @replaying
      end

      def force_utf8(data)
        case data.class.to_s
        when /String/
          data.force_encoding('utf-8')
        when /Hash/
          data.each { |k, v| data[k] = force_utf8(v) }
        when /Array/
          data.map { |s| force_utf8(s) }
        end
      end
    end

    alias_method :_idle, :idle
    alias_method :_idle_done, :idle_done

    def idle(&response_handler)
      if Net::IMAP.replaying?
        @idle_done_cond = new_cond
        @idle_done = false
      end

      response = mock_command(:_idle, 'IDLE', &response_handler)

      if Net::IMAP.replaying?
        synchronize do
          unless @idle_done
            @idle_done_cond.wait(0.1)
            raise('The IDLE has not done') unless @idle_done
          end
          @idle_done_cond = nil
        end
      end

      response
    end

    def idle_done
      if Net::IMAP.replaying?
        synchronize do
          if @idle_done_cond.nil?
            raise Net::IMAP::Error, 'not during IDLE'
          end
          @idle_done = true
          idle_done_cond.signal
        end
      else
        _idle_done
      end
    end

    private

    alias_method :_send_command, :send_command

    def send_command(cmd, *args, &block)
      mock_command(:_send_command, cmd, *args, &block)
    end

    def mock_command(method, cmd, *args, &block)
      # In Ruby 1.9.x, strings default to binary which causes the digest to be
      # different.
      clean_args = args.dup.each do |s|
        Net::IMAP.force_utf8(s)
      end

      yaml_dump = YAML.dump([cmd] + clean_args)

      if RUBY_VERSION =~ /^(1.9|2.0)/
        # From 1.9 to 2.0 to 2.1, the way YAML encodes special characters changed.
        # Here's what each returns for: YAML.dump(["", "%"])
        #   1.9.x: "---\n- ''\n- ! '%'\n"
        #   2.0.x: "---\n- ''\n- '%'\n"
        #   2.1.x: "---\n- ''\n- \"%\"\n"
        # The `gsub` here converts the older format into the 2.1.x.
        yaml_dump.gsub!(/(?:! )?'(.+)'/, '"\1"')

        # In 1.9 and 2.0 strings starting with `+` or `-` are not escaped in quotes, but
        # they are in 2.1+. This addresses that.
        yaml_dump.gsub!(/ ([+-](?:X-GM-\w+|FLAGS))/, ' "\1"')

        # In 1.9 and 2.0 strings starting with `\` are not escaped in quotes, but
        # they are in 2.1+. This addresses that. Yes we need all those backslashes :|
        yaml_dump.gsub!(/ \\(\w+)/, ' "\\\\\\\\\1"')
      end

      digest = "#{cmd}-#{Digest::MD5.hexdigest(yaml_dump)}"

      if Net::IMAP.replaying?
        recordings = Net::IMAP.recordings[digest] || []
        if recordings.empty?
          # Be lenient if LOGOUT is called but wasn't explicitly recorded. This
          # comes up often when called from `at_exit`.
          cmd == 'LOGOUT' ? return : raise('Could not find recording')
        end

        action, response, @responses, all_responses = recordings.shift

        if block && all_responses
          all_responses.each do |resp|
            yield(resp)
          end
        end
      else
        action = :return
        all_responses = []
        begin
          args.unshift(cmd) if method==:_send_command
          response = send(method, *args) do |resp|
            all_responses << resp
            yield(resp)
          end
        rescue StandardError => e
          action = :raise
          response = e
        end

        # @responses (the third argument here) contains untagged responses captured
        # via the Net::IMAP#record_response method.
        Net::IMAP.recordings[digest] ||= []
        Net::IMAP.recordings[digest] << [action, response.dup, @responses ? @responses.dup : nil, all_responses]
      end

      raise(response) if action == :raise

      response
    end
  end
end

module Spec
  module ImapMock
    # Configures RSpec with an around(:each) block to use IMAP mocks
    def self.configure_rspec!(config)
      config.around(:each) do |example|
        Spec::ImapMock.run_rspec_example(example)
      end
    end

    # Run an RSpec example using IMAP mocks
    def self.run_rspec_example(example)
      # The path is determined by the rspec `describe`s and `context`s
      mock_path = example.example_group.to_s
                         .gsub(/RSpec::ExampleGroups::/, '')
                         .gsub(/(\w)([A-Z])/, '\1_\2')
                         .gsub(/::/, '/')
                         .downcase

      # The name is determined by the description of the example.
      mock_name = example.description.gsub(/[^\w\-\/]+/, '_').downcase

      filename = File.join('spec/recordings/', mock_path, "#{mock_name}.yml")

      # If we've already recorded this spec load the recordings
      Net::IMAP.recordings = File.exist?(filename) ? YAML.load_file(filename) : nil

      example.run

      # If we haven't yet recorded the spec and there were some recordings,
      # write them to a file.
      return if File.exist?(filename) or Net::IMAP.recordings.empty?
      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, 'w') { |f| YAML.dump(Net::IMAP.recordings, f) }
    end
  end
end

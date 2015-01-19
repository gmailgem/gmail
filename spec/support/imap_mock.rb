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
    end

    private

    alias_method :_send_command, :send_command

    def send_command(cmd, *args, &block)
      # In Ruby 1.9.x, strings default to binary which causes the digest to be
      # different.
      clean_args = args.dup.each do |s|
        s.is_a?(String) ? s.force_encoding('utf-8') : s
      end

      # From 1.9 to 2.0 to 2.1, the way YAML encodes special characters changed.
      # Here's what each returns for: YAML.dump(["", "%"])
      #   1.9.x: "---\n- ''\n- ! '%'\n"
      #   2.0.x: "---\n- ''\n- '%'\n"
      #   2.1.x: "---\n- ''\n- \"%\"\n"
      # The `gsub` here converts the older format into the 2.1.x.
      yaml_dump = YAML.dump([cmd] + clean_args).gsub(/(?:! )?'(.+)'/, '"\1"')

      digest = "#{cmd}-#{Digest::MD5.hexdigest(yaml_dump)}"

      if Net::IMAP.replaying?
        recordings = Net::IMAP.recordings[digest] || []
        if recordings.empty?
          # Be lenient if LOGOUT is called but wasn't explicitly recorded. This
          # comes up often when called from `at_exit`.
          cmd == 'LOGOUT' ? return : raise('Could not find recording')
        end

        action, response, @responses = recordings.shift
      else
        action = :return
        begin
          response = _send_command(cmd, *args, &block)
        rescue => e
          action = :raise
          response = e
        end

        # @responses (the third argument here) contains untagged responses captured
        # via the Net::IMAP#record_response method.
        Net::IMAP.recordings[digest] ||= []
        Net::IMAP.recordings[digest]  << [action, response.dup, @responses ? @responses.dup : nil]
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
      unless File.exist?(filename) or Net::IMAP.recordings.empty?
        FileUtils.mkdir_p(File.dirname(filename))
        File.open(filename, 'w') { |f| YAML.dump(Net::IMAP.recordings, f) }
      end
    end
  end
end

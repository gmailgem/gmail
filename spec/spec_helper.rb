$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'rspec'
require 'yaml'
require 'gmail'

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
      digest = "#{cmd}-#{Digest::MD5.hexdigest(YAML.dump([cmd] + args))}"

      if Net::IMAP.replaying?
        recordings = Net::IMAP.recordings[digest] || []
        raise('Could not find recording') if recordings.empty?

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

RSpec.configure do |config|
  config.around(:each) do |example|
    mock_path = example.example_group.to_s
      .gsub(/RSpec::ExampleGroups::/, '')
      .gsub(/(\w)([A-Z])/, '\1_\2')
      .gsub(/::/, '/')
      .downcase

    mock_name = example.description.gsub(/[^\w\-\/]+/, '_').downcase

    filename = File.join('spec/recordings/', mock_path, "#{mock_name}.yml")

    Net::IMAP.recordings = File.exist?(filename) ? YAML.load_file(filename) : nil

    example.run

    unless File.exist?(filename) or Net::IMAP.recordings.empty?
      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, 'w') { |f| YAML.dump(Net::IMAP.recordings, f) }
    end
  end
end

def within_gmail(&block)
  gmail = Gmail.connect!(*TEST_ACCOUNT)
  yield(gmail)
  gmail.logout if gmail
end

def mock_client(&block)
  client = Gmail::Client::Plain.new(*TEST_ACCOUNT)
  if block_given?
    client.connect
    yield client
    client.logout
  end
  client
end

def mock_mailbox(box="INBOX", &block)
  within_gmail do |gmail|
    mailbox = subject.new(gmail, box)
    yield(mailbox) if block_given?
    mailbox
  end
end

# Run test by creating your own test account with credentials in account.yml
# Otherwise default credentials from an obfuscated file are used.
require 'obfuscation'
clear_file = File.join(File.dirname(__FILE__), 'account.yml')
obfus_file = File.join(File.dirname(__FILE__), 'account.yml.obfus')
if File.exist?(clear_file)
  TEST_ACCOUNT = YAML.load_file(clear_file)
elsif File.exist?(obfus_file)
  TEST_ACCOUNT = Spec::Obfuscation.decrypt_file(obfus_file)
else
  raise 'account.yml file not found'
end

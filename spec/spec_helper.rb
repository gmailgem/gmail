$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'rspec'
require 'yaml'
require 'gmail'
require 'coveralls'

Coveralls.wear!

# require_support_files
Dir[File.join(File.dirname(__FILE__), 'support', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  Spec::ImapMock.configure_rspec!(config)
end

def within_gmail(&block)
  Gmail.connect!(*TEST_ACCOUNT) do |gmail|
    yield(gmail)
  end
end

def mock_client(&block)
  client = Gmail::Client::Plain.new(*TEST_ACCOUNT)
  client.connect

  if block_given?
    client.login
    yield client
    client.logout
  end

  client
end

def mock_mailbox(box = "INBOX", &block)
  within_gmail do |gmail|
    mailbox = gmail.mailbox(box)
    yield(mailbox) if block_given?
    mailbox
  end
end

# TODO: move this to it's own dir; get rid of global variable
# Run test by creating your own test account with credentials in account.yml
# Otherwise default credentials from an obfuscated file are used.
clear_file = File.join(File.dirname(__FILE__), 'account.yml')
obfus_file = File.join(File.dirname(__FILE__), 'account.yml.obfus')
if File.exist?(clear_file)
  TEST_ACCOUNT = YAML.load_file(clear_file)
elsif File.exist?(obfus_file)
  TEST_ACCOUNT = Spec::Obfuscation.decrypt_file(obfus_file)
else
  raise 'account.yml file not found'
end

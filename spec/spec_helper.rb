$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'rspec'
require 'yaml'
require 'gmail'
require 'camcorder'
require 'camcorder/rspec'

Camcorder.config.recordings_dir = 'spec/recordings'

RSpec.configure do |config|
  config.before(:suite) do
    Camcorder.intercept_constructor(Net::IMAP) do
      methods_with_side_effects :login, :logout, :list, :examine, :select, :create, :delete
    end

    Camcorder.intercept_constructor(Net::SMTP)
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

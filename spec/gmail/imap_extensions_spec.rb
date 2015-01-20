require 'rubygems'
require 'rspec'
require 'net/imap'
require 'gmail/imap_extensions'

describe Gmail::ImapExtensions do
  it 'does not modify arity' do
    Gmail::ImapExtensions::patch_net_imap_response_parser
    expect(Net::IMAP::ResponseParser.new).to respond_to(:msg_att).with(0).arguments
    expect(Net::IMAP::ResponseParser.new).to respond_to(:msg_att).with(1).arguments
  end
end

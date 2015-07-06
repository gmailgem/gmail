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

  it 'parses 1 label without spaces correctly' do
    Gmail::ImapExtensions::patch_net_imap_response_parser
    server_response = %[* 1 FETCH (X-GM-LABELS (Hello))\r\n]
    parsed_labels = Net::IMAP::ResponseParser.new.parse(server_response).data.attr["X-GM-LABELS"]
    expect(parsed_labels).to contain_exactly("Hello")
  end

  it 'parses 2 label without spaces correctly' do
    Gmail::ImapExtensions::patch_net_imap_response_parser
    server_response = %[* 1 FETCH (X-GM-LABELS (Hello World))\r\n]
    parsed_labels = Net::IMAP::ResponseParser.new.parse(server_response).data.attr["X-GM-LABELS"]
    expect(parsed_labels).to contain_exactly("World", "Hello")
  end

  it 'parses 1 label with a space correctly' do
    Gmail::ImapExtensions::patch_net_imap_response_parser
    server_response = %[* 1 FETCH (X-GM-LABELS ("Hello World"))\r\n]
    parsed_labels = Net::IMAP::ResponseParser.new.parse(server_response).data.attr["X-GM-LABELS"]
    expect(parsed_labels).to contain_exactly("Hello World")
  end

  it 'parses 2 labels, each with a space, correctly' do
    Gmail::ImapExtensions::patch_net_imap_response_parser
    server_response = %[* 1 FETCH (X-GM-LABELS ("Foo Bar" "Hello World"))\r\n]
    parsed_labels = Net::IMAP::ResponseParser.new.parse(server_response).data.attr["X-GM-LABELS"]
    expect(parsed_labels).to contain_exactly("Hello World", "Foo Bar")
  end

  it 'parses a mixture of space and non-space labels correctly' do
    Gmail::ImapExtensions::patch_net_imap_response_parser
    server_response = %[* 1 FETCH (X-GM-LABELS ("Foo Bar" "\\Important" Hello World))\r\n]
    parsed_labels = Net::IMAP::ResponseParser.new.parse(server_response).data.attr["X-GM-LABELS"]
    expect(parsed_labels).to contain_exactly(:Important, "Hello", "World", "Foo Bar")
  end
end

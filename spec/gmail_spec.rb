require 'spec_helper'
require 'net/imap'

describe Gmail do
  it "should be able to convert itself to IMAP date format" do
    expect(Net::IMAP.format_date(Date.new(1988, 12, 20))).to eq("20-Dec-1988")
  end

  %w[new new!].each do |method|
    it "##{method} connects with Gmail service and return valid connection object" do
      gmail = Gmail.send(method, *TEST_ACCOUNT)
      expect(gmail).to be_kind_of(Gmail::Client::Plain)
      expect(gmail.connection).not_to be_nil
      expect(gmail).to be_logged_in
    end

    it "##{method} connects with client and give it context when block given" do
      Gmail.send(method, *TEST_ACCOUNT) do |gmail|
        expect(gmail).to be_kind_of(Gmail::Client::Plain)
        expect(gmail.connection).not_to be_nil
        expect(gmail).to be_logged_in
      end
    end
  end

  it "#new does not raise error when couldn't connect with given account" do
    expect do
      gmail = Gmail.new("foo", "bar")
      expect(gmail).not_to be_logged_in
    end.not_to raise_error
  end

  it "#new! raises error when couldn't connect with given account" do
    expect do
      gmail = Gmail.new!("foo", "bar")
      expect(gmail).not_to be_logged_in
    end.to raise_error
      ### FIX: can someone dig to the bottom of this?  We are getting NoMethodError instead of Gmail::Client::AuthorizationError in 1.9
  end
end

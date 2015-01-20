require 'spec_helper'

describe Gmail::Mailbox do
  subject { Gmail::Mailbox }

  context "on initialize" do
    it "sets client and name" do
      within_gmail do |gmail|
        mailbox = subject.new(gmail, "TEST")
        expect(mailbox.instance_variable_get("@gmail")).to eq(gmail)
        expect(mailbox.name).to eq("TEST")
      end
    end

    it "works in INBOX by default" do
      within_gmail do |gmail|
        mailbox = subject.new(@gmail)
        expect(mailbox.name).to eq("INBOX")
      end
    end
  end

  context "instance" do
    it "counts all emails" do
      mock_mailbox do |mailbox|
        expect(mailbox.count).to be > 0
      end
    end

    it "finds messages" do
      mock_mailbox do |mailbox|
        message = mailbox.emails.first
        mailbox.emails(:all, :from => message.from.first.name) == message.from.first.name
      end
    end

    it "performs full text search of message bodies" do
      skip "This can wait..."
      # mock_mailbox do |mailbox|
      #  message = mailbox.emails.first
      #  body = message.parts.blank? ? message.body.decoded : message.parts[0].body.decoded
      #  emails = mailbox.emails(:search => body.split(' ').first)
      #  emails.size.should > 0
      # end
    end
  end
end

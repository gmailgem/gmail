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

    it "waits once" do
      mock_mailbox do |mailbox|
        response = nil
        mailbox.wait_once { |r| response = r }
        expect(response).to be_kind_of(Net::IMAP::UntaggedResponse)
        expect(response.name).to eq("EXISTS")
      end
    end

    it "waits with an unblocked connection" do
      mock_mailbox do |mailbox|
        mailbox.wait_once do |r|
          expect(mailbox.count).to be > 0
        end
      end
    end

    it "waits repeatedly" do
      responses = []
      mock_mailbox do |mailbox|
        mailbox.wait do |r|
          responses << r
          break if responses.size == 2
        end
      end

      expect(responses.size).to eq(2)
    end

    it "waits with 29-minute re-issue" do
      client = mock_client
      expect(client.conn).to receive(:idle).and_call_original.at_least(:twice)

      mailbox = client.inbox
      mailbox.wait_once(:idle_timeout => 0.001)
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

require 'spec_helper'

describe Gmail::Client::Plain do
  subject { Gmail::Client::Plain }

  context "on initialize" do
    it "sets username, password and options" do
      client = subject.new("test@gmail.com", "pass", :foo => :bar)
      expect(client.username).to eq("test@gmail.com")
      expect(client.password).to eq("pass")
      expect(client.options[:foo]).to eq(:bar)
    end

    it "converts simple name to gmail email" do
      client = subject.new("test", "pass")
      expect(client.username).to eq("test@gmail.com")
    end
  end

  context "instance" do
    it "connects to Gmail IMAP service" do
      client = mock_client
      expect(client.connect!).to be_truthy
    end

    it "properly logs in to valid Gmail account" do
      client = mock_client
      expect(client.connect).to be_truthy
      expect(client.login).to be_truthy
      expect(client).to be_logged_in
      client.logout
    end

    it "raises error when given Gmail account is invalid and errors enabled" do
      expect do
        client = Gmail::Client::Plain.new("foo", "bar")
        expect(client.connect).to be_truthy
        expect(client.login!).not_to be_nil
      end.to raise_error
    end

    it "does not raise error even though Gmail account is invalid" do
      expect do
        client = Gmail::Client::Plain.new("foo", "bar")
        expect(client.connect).to be_truthy
        expect(client.login).to_not be_truthy
      end.not_to raise_error
    end

    it "does not log in when given Gmail account is invalid" do
      client = Gmail::Client::Plain.new("foo", "bar")
      expect(client.connect).to be_truthy
      expect(client.login).to be_falsey
    end

    it "properly logs out from Gmail" do
      client = mock_client
      expect(client.login).to be_truthy
      expect(client.logout).to be_truthy
      expect(client).not_to be_logged_in
    end

    it "#connection automatically logs in to Gmail account when it's called" do
      client = mock_client
      expect(client).to receive(:login).once.and_return(false)

      expect(client.connection).not_to be_nil
    end

    it "properly composes message" do
      mail = mock_client.compose do
        from "test@gmail.com"
        to "friend@gmail.com"
        subject "Hello world!"
      end
      expect(mail.from).to eq(["test@gmail.com"])
      expect(mail.to).to eq(["friend@gmail.com"])
      expect(mail.subject).to eq("Hello world!")
    end

    it "#compose automatically adds `from` header when it is not specified" do
      mail = mock_client.compose
      expect(mail.from).to eq([TEST_ACCOUNT[0]])
      mail = mock_client.compose(Mail.new)
      expect(mail.from).to eq([TEST_ACCOUNT[0]])
      mail = mock_client.compose {}
      expect(mail.from).to eq([TEST_ACCOUNT[0]])
    end

    it "delivers inline composed email" do
      allow_any_instance_of(Mail::Message).to receive(:deliver!).and_return true
      mock_client do |client|
        response = client.deliver do
          to TEST_ACCOUNT[0]
          subject "Hello world!"
          body "Yeah, hello there!"
        end

        expect(response).to be_truthy
      end
    end

    it "does not raise error when mail can't be delivered and errors are disabled" do
      expect do
        client = mock_client
        expect(client.deliver(Mail.new {})).to be false
      end.not_to raise_error
    end

    it "raises error when mail can't be delivered and errors are disabled" do
      expect do
        client = mock_client
        client.deliver!(Mail.new {})
      end.to raise_error(Gmail::Client::DeliveryError)
    end

    it "properly switches to given mailbox" do
      mock_client do |client|
        mailbox = client.mailbox("INBOX")
        expect(mailbox).to be_kind_of(Gmail::Mailbox)
        expect(mailbox.name).to eq("INBOX")
      end
    end

    it "properly switches to given mailbox using block style" do
      mock_client do |client|
        client.mailbox("INBOX") do |mailbox|
          expect(mailbox).to be_kind_of(Gmail::Mailbox)
          expect(mailbox.name).to eq("INBOX")
        end
      end
    end

    context "labels" do
      subject do
        client = Gmail::Client::Plain.new(*TEST_ACCOUNT)
        client.connect
        client.labels
      end

      it "returns list of all available labels" do
        labels = subject
        expect(labels.all).to include("INBOX")
      end

      it "checks if there is given label defined" do
        labels = subject
        expect(labels.exists?("INBOX")).to be true
        expect(labels.exists?("FOOBAR")).to be false
      end

      it "creates given label" do
        labels = subject
        labels.create("MYLABEL")
        expect(labels.exists?("MYLABEL")).to be true
        expect(labels.create("MYLABEL")).to be false
        labels.delete("MYLABEL")
      end

      it "removes existing label" do
        labels = subject
        labels.create("MYLABEL")
        expect(labels.delete("MYLABEL")).to be true
        expect(labels.exists?("MYLABEL")).to be false
        expect(labels.delete("MYLABEL")).to be false
      end
    end
  end
end

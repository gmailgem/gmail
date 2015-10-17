require 'spec_helper'

describe Gmail::Client::XOAuth2 do
  subject { Gmail::Client::XOAuth2 }

  context "on initialize" do
    it "sets username, oauth2_token and options" do
      client = subject.new("test@gmail.com", {
        :token => "token",
        :foo   => :bar
      })
      expect(client.username).to eq("test@gmail.com")
      expect(client.token).to eq({ :token => "token", :foo => :bar })
    end

    it "converts simple name to gmail email" do
      client = subject.new("test", { :token => "token" })
      expect(client.username).to eq("test@gmail.com")
    end
  end

  context "instance" do
    def mock_client(&block)
      client = Gmail::Client::XOAuth2.new(*TEST_ACCOUNT)
      if block_given?
        client.connect
        yield client
        client.logout
      end
      client
    end

    it "connects to Gmail IMAP service" do
      expect(-> do
        client = mock_client
        expect(client.connect!).to be_truthy
      end).to_not raise_error
    end

    it "properly logs in to valid Gmail account" do
      pending
      client = mock_client
      expect(client.connect).to be_truthy
      expect(client.login).to be_truthy
      expect(client).to be_logged_in
      client.logout
    end

    it "raises error when given Gmail account is invalid and errors enabled" do
      expect(-> do
        client = Gmail::Client::XOAuth2.new("foo", { :token => "bar" })
        expect(client.connect).to be_truthy
        expect(client.login!).not_to be_truthy
      end).to raise_error(Gmail::Client::AuthorizationError)
    end

    it "does not log in when given Gmail account is invalid" do
      expect(-> do
        client = Gmail::Client::XOAuth2.new("foo", { :token => "bar" })
        expect(client.connect).to be_truthy
        expect(client.login).not_to be_truthy
      end).to_not raise_error
    end

    it "properly logs out from Gmail" do
      pending
      client = mock_client
      client.connect
      expect(client.login).to be_truthy
      expect(client.logout).to be_truthy
      expect(client).not_to be_logged_in
    end

    it "#connection automatically logs in to Gmail account when it's called" do
      mock_client do |client|
        expect(client).to receive(:login).once.and_return(false)
        expect(client.connection).not_to be_nil
      end
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
      pending
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
      expect(-> do
        client = mock_client
        expect(client.deliver(Mail.new {})).to be_falsey
      end).to_not raise_error
    end

    it "raises error when mail can't be delivered and errors are disabled" do
      expect(-> do
        client = mock_client
        client.deliver!(Mail.new {})
      end).to raise_error(Gmail::Client::DeliveryError)
    end

    it "properly switches to given mailbox" do
      pending
      mock_client do |client|
        mailbox = client.mailbox("TEST")
        expect(mailbox).to be_kind_of(Gmail::Mailbox)
        expect(mailbox.name).to eq("TEST")
      end
    end

    it "properly switches to given mailbox using block style" do
      pending
      mock_client do |client|
        client.mailbox("TEST") do |mailbox|
          expect(mailbox).to be_kind_of(Gmail::Mailbox)
          expect(mailbox.name).to eq("TEST")
        end
      end
    end

    context "labels" do
      subject do
        client = Gmail::Client::XOAuth2.new(*TEST_ACCOUNT)
        client.connect
        client.labels
      end

      it "returns list of all available labels" do
        pending
        labels = subject
        expect(labels.all).to include("TEST", "INBOX")
      end

      it "checks if there is given label defined" do
        pending
        labels = subject
        expect(labels.exists?("TEST")).to be_truthy
        expect(labels.exists?("FOOBAR")).to be_falsey
      end

      it "creates given label" do
        pending
        labels = subject
        labels.create("MYLABEL")
        expect(labels.exists?("MYLABEL")).to be_truthy
        expect(labels.create("MYLABEL")).to be_falsey
        labels.delete("MYLABEL")
      end

      it "removes existing label" do
        pending
        labels = subject
        labels.create("MYLABEL")
        expect(labels.delete("MYLABEL")).to be_truthy
        expect(labels.exists?("MYLABEL")).to be_falsey
        expect(labels.delete("MYLABEL")).to be_falsey
      end
    end
  end
end

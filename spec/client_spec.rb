require 'spec_helper'

describe "Gmail client (Plain)" do
  subject { Gmail::Client::Plain }

  context "on initialize" do
    it "should set username, password and options" do
      client = subject.new("test@gmail.com", "pass", :foo => :bar)
      client.username.should == "test@gmail.com"
      client.password.should == "pass"
      client.options[:foo].should == :bar
    end

    it "should convert simple name to gmail email" do
      client = subject.new("test", "pass")
      client.username.should == "test@gmail.com"
    end
  end

  context "instance" do
    it "should connect to GMail IMAP service" do
      client = mock_client
      client.connect!.should be_truthy
    end

    it "should properly login to valid GMail account" do
      client = mock_client
      client.connect.should be_truthy
      client.login.should be_truthy
      client.should be_logged_in
      client.logout
    end

    it "should raise error when given GMail account is invalid and errors enabled" do
      lambda {
        client = Gmail::Client::Plain.new("foo", "bar")
        client.connect.should be_truthy
        client.login!.should_not be_nil
        }.should raise_error
        ### FIX: can someone dig to the bottom of this?  We are getting NoMethodError instead of Gmail::Client::AuthorizationError in 1.9
    end

    it "shouldn't raise error even though GMail account is invalid" do
      lambda {
        client = Gmail::Client::Plain.new("foo", "bar")
        client.connect.should be_truthy
        expect(client.login).to_not be_truthy
      }.should_not raise_error
    end

    it "shouldn't login when given GMail account is invalid" do
      client = Gmail::Client::Plain.new("foo", "bar")
      client.connect.should be_truthy
      client.login.should be_falsey
    end

    it "should properly logout from GMail" do
      client = mock_client
      client.connect
      client.login.should be_truthy
      client.logout.should be_truthy
      client.should_not be_logged_in
    end

    it "#connection should automatically log in to GMail account when it's called" do
      mock_client do |client|
        expect(client).to receive(:login).once.and_return(false)
        client.connection.should_not be_nil
      end
    end

    it "should properly compose message" do
      mail = mock_client.compose do
        from "test@gmail.com"
        to "friend@gmail.com"
        subject "Hello world!"
      end
      mail.from.should == ["test@gmail.com"]
      mail.to.should == ["friend@gmail.com"]
      mail.subject.should == "Hello world!"
    end

    it "#compose should automatically add `from` header when it is not specified" do
      mail = mock_client.compose
      mail.from.should == [TEST_ACCOUNT[0]]
      mail = mock_client.compose(Mail.new)
      mail.from.should == [TEST_ACCOUNT[0]]
      mail = mock_client.compose {}
      mail.from.should == [TEST_ACCOUNT[0]]
    end

    it "should deliver inline composed email" do
      mock_client do |client|
        client.deliver do
          to TEST_ACCOUNT[0]
          subject "Hello world!"
          body "Yeah, hello there!"
        end.should be_truthy
      end
    end

    it "should not raise error when mail can't be delivered and errors are disabled" do
      lambda {
        client = mock_client
        client.deliver(Mail.new {}).should be false
      }.should_not raise_error
    end

    it "should raise error when mail can't be delivered and errors are disabled" do
      lambda {
        client = mock_client
        client.deliver!(Mail.new {})
      }.should raise_error(Gmail::Client::DeliveryError)
    end

    it "should properly switch to given mailbox" do
      mock_client do |client|
        mailbox = client.mailbox("INBOX")
        mailbox.should be_kind_of(Gmail::Mailbox)
        mailbox.name.should == "INBOX"
      end
    end

    it "should properly switch to given mailbox using block style" do
      mock_client do |client|
        client.mailbox("INBOX") do |mailbox|
          mailbox.should be_kind_of(Gmail::Mailbox)
          mailbox.name.should == "INBOX"
        end
      end
    end

    context "labels" do
      let(:client) { Gmail::Client::Plain.new(*TEST_ACCOUNT) }

      subject {
        client.connect
        client.login
        client.labels
      }

      after { client.logout if client.logged_in? }

      it "should get list of all available labels" do
        labels = subject
        labels.all.should include("INBOX")
      end

      it "should be able to check if there is given label defined" do
        labels = subject
        labels.exists?("INBOX").should be true
        labels.exists?("FOOBAR").should be false
      end

      it "should be able to create given label" do
        labels = subject
        labels.create("MYLABEL")
        labels.exists?("MYLABEL").should be true
        labels.create("MYLABEL").should be false
        labels.delete("MYLABEL")
      end

      it "should be able to remove existing label" do
        labels = subject
        labels.create("MYLABEL")
        labels.delete("MYLABEL").should be true
        labels.exists?("MYLABEL").should be false
        labels.delete("MYLABEL").should be false
      end
    end
  end
end

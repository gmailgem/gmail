require 'spec_helper'

describe Gmail::Message do
  describe "initialize" do
    let(:client) { mock_client }
    let(:mailbox) { client.mailbox(:all) }

    subject do
      mailbox.emails.first
    end

    it "should set uid and mailbox" do
      subject.instance_variable_get(:@mailbox).should be_a Gmail::Mailbox
      subject.instance_variable_get(:@gmail).should be_a Gmail::Client::Base
      subject.instance_variable_get(:@uid).should be_a Integer
      subject.labels
    end
  end

  describe "mocks" do
    subject { Gmail::Message.new(double(:mailbox, :name => 'INBOX'), nil) }
    before  { allow_any_instance_of(Gmail::Message).to receive(:fetch).and_return('foo') }

    describe "#mark" do
      it "should be able to mark itself as read" do
        expect(subject).to receive(:read!).with(no_args).once
        subject.mark(:read)
      end

      it "should be able to mark itself as unread" do
        expect(subject).to receive(:unread!).with(no_args).once
        subject.mark(:unread)
      end

      it "should be able to mark itself as deleted" do
        expect(subject).to receive(:delete!).with(no_args).once
        subject.mark(:deleted)
      end

      it "should be able to mark itself as spam" do
        expect(subject).to receive(:spam!).with(no_args).once
        subject.mark(:spam)
      end

      it "should be able to mark itself with a flag" do
        expect(subject).to receive(:flag).with(:my_flag).once
        subject.mark(:my_flag)
      end
    end

    describe "#read!" do
      it "should flag itself as :Seen" do
        expect(subject).to receive(:flag).with(:Seen).once
        subject.read!
      end
    end

    describe "#unread!" do
      it "should unflag :Seen from itself" do
        expect(subject).to receive(:unflag).with(:Seen).once
        subject.unread!
      end
    end

    describe "#star!" do
      it "should flag itself as '[Gmail]/Starred'" do
        expect(subject).to receive(:flag).with(:Flagged).once
        subject.star!
      end
    end

    describe "#unstar!" do
      it "should unflag '[Gmail]/Starred' from itself" do
        expect(subject).to receive(:unflag).with(:Flagged).once
        subject.unstar!
      end
    end

    describe "#spam!" do
      it "should move itself to the spam folder" do
        expect(subject).to receive(:add_label).with("\\Spam").once
        subject.spam!
      end
    end

    describe "#archive!" do
      it "should remove itself from the inbox" do
        expect(subject).to receive(:remove_label).with("\\Inbox").once
        subject.archive!
      end
    end
  end

  describe "instance methods" do
    let(:client) { mock_client }
    let(:message) { client.mailbox(:all).emails(:unread, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").last }

    after { client.logout if client.logged_in? }

    it "should be able to set given label" do
      message.add_label 'Awesome'
      message.add_label 'Great'

      message.labels.should include("Awesome")
      message.labels.should include("Great")
      message.labels.should include("\\Inbox")
    end

    it "should remove a given label" do
      message.add_label 'Awesome'
      message.add_label 'Great'

      message.remove_label 'Awesome'
      message.labels.should_not include("Awesome")
      message.labels.should include("Great")
      message.labels.should include("\\Inbox")
      message.flags.should_not include(:Seen)
    end

    it "should be able to set given label with old method" do
      message.label! 'Awesome'
      message.label! 'Great'
      message.labels.should include("Great")
      message.labels.should include("Awesome")
      message.labels.should include("\\Inbox")
    end

    it "should remove a given label with old method" do
      message.add_label 'Awesome'
      message.add_label 'Great'

      message.remove_label! 'Awesome'
      message.labels.should_not include("Awesome")
      message.labels.should include("Great")
      message.labels.should include("\\Inbox")
      message.flags.should_not include(:Seen)
    end

    it "should allow moving from one tag to other" do
      message.add_label 'Awesome'
      message.remove_label 'Great'

      message.move_to('Great', 'Awesome')
      message.labels.should include("Great")
      message.labels.should_not include("Awesome")
      message.labels.should include("\\Inbox")
    end

    it "should be able to mark itself with given flag" do
      message.mark(:Seen)
      message.flags.should include(:Seen)
    end

    it "should be able to delete itself" do
      trash_count = client.mailbox(:trash).emails.count

      message.delete!

      expect(client.mailbox(:trash).emails.count).to eq(trash_count + 1)
    end
  end
end

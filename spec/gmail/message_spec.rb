require 'spec_helper'

describe Gmail::Message do
  describe "initialize" do
    let(:client) { mock_client }
    let(:mailbox) { client.mailbox(:all) }

    subject do
      mailbox.emails.first
    end

    it "sets uid and mailbox" do
      expect(subject.instance_variable_get(:@mailbox)).to be_a Gmail::Mailbox
      expect(subject.instance_variable_get(:@gmail)).to be_a Gmail::Client::Base
      expect(subject.instance_variable_get(:@uid)).to be_a Integer
      subject.labels
    end

    it "sets PREFETCH_ATTRS" do
      expect(subject.uid).to be_a Integer
      expect(subject.msg_id).to be_a Integer
      expect(subject.thr_id).to be_a Integer
      expect(subject.envelope).to be_a Net::IMAP::Envelope
      expect(subject.message).to be_a Mail::Message
      expect(subject.flags).to be_a Array
      expect(subject.labels).to be_a Array
    end
  end

  describe "mocks" do
    subject { Gmail::Message.new(double(:mailbox, :name => 'INBOX'), nil) }
    before  { allow_any_instance_of(Gmail::Message).to receive(:fetch).and_return('foo') }

    describe "#mark" do
      it "marks itself as read" do
        expect(subject).to receive(:read!).with(no_args).once
        subject.mark(:read)
      end

      it "marks itself as unread" do
        expect(subject).to receive(:unread!).with(no_args).once
        subject.mark(:unread)
      end

      it "marks itself as deleted" do
        expect(subject).to receive(:delete!).with(no_args).once
        subject.mark(:deleted)
      end

      it "marks itself as spam" do
        expect(subject).to receive(:spam!).with(no_args).once
        subject.mark(:spam)
      end

      it "marks itself with a flag" do
        expect(subject).to receive(:flag).with(:my_flag).once
        subject.mark(:my_flag)
      end
    end

    describe "#read!" do
      it "flags itself as :Seen" do
        expect(subject).to receive(:flag).with(:Seen).once
        subject.read!
      end
    end

    describe "#unread!" do
      it "unflags :Seen from itself" do
        expect(subject).to receive(:unflag).with(:Seen).once
        subject.unread!
      end
    end

    describe "#star!" do
      it "flags itself as '[Gmail]/Starred'" do
        expect(subject).to receive(:flag).with(:Flagged).once
        subject.star!
      end
    end

    describe "#unstar!" do
      it "unflags '[Gmail]/Starred' from itself" do
        expect(subject).to receive(:unflag).with(:Flagged).once
        subject.unstar!
      end
    end

    describe "#spam!" do
      it "moves itself to the spam folder" do
        expect(subject).to receive(:add_label).with("\\Spam").once
        subject.spam!
      end
    end

    describe "#archive!" do
      it "removes itself from the inbox" do
        expect(subject).to receive(:remove_label).with("\\Inbox").once
        subject.archive!
      end
    end
  end

  describe "instance methods" do
    let(:client) { mock_client }
    let(:message) { client.mailbox(:all).emails(:unread, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").last }

    after { client.logout if client.logged_in? }

    it "sets given label" do
      message.add_label 'Awesome'
      message.add_label 'Great'

      expect(message.labels).to include("Awesome")
      expect(message.labels).to include("Great")
      expect(message.labels).to include(:Inbox)
    end

    it "removes a given label" do
      message.add_label 'Awesome'
      message.add_label 'Great'

      message.remove_label 'Awesome'
      expect(message.labels).not_to include("Awesome")
      expect(message.labels).to include("Great")
      expect(message.labels).to include(:Inbox)
      expect(message.flags).not_to include(:Seen)
    end

    it "sets given label with old method" do
      message.label! 'Awesome'
      message.label! 'Great'
      expect(message.labels).to include("Great")
      expect(message.labels).to include("Awesome")
      expect(message.labels).to include(:Inbox)
    end

    it "removes a given label with old method" do
      message.add_label 'Awesome'
      message.add_label 'Great'

      message.remove_label! 'Awesome'
      expect(message.labels).not_to include("Awesome")
      expect(message.labels).to include("Great")
      expect(message.labels).to include(:Inbox)
      expect(message.flags).not_to include(:Seen)
    end

    it "moves from one tag to other" do
      message.add_label 'Awesome'
      message.remove_label 'Great'

      message.move_to('Great', 'Awesome')
      expect(message.labels).to include("Great")
      expect(message.labels).not_to include("Awesome")
      expect(message.labels).to include(:Inbox)
    end

    it "marks itself read" do
      message.mark(:unread)

      message.mark(:read)
      expect(message.flags).to include(:Seen)
    end

    it "marks itself unread" do
      message.mark(:read)

      message.mark(:unread)
      expect(message.flags).not_to include(:Seen)
    end

    it "deletes itself" do
      trash_count = client.mailbox(:trash).emails.count

      message.delete!

      expect(client.mailbox(:trash).emails.count).to eq(trash_count + 1)
    end
  end
end

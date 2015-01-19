require 'spec_helper'

describe Gmail::Message do

  describe "initialize" do
    let(:uid) { 123456 }

    subject do
      message = nil
      mock_mailbox('[Gmail]/All Mail') do |mailbox|
        message = Gmail::Message.new(mailbox, uid)
      end
      message
    end

    it "should set uid and mailbox" do
      pending # can't figure this one out
      subject.instance_variable_get(:@mailbox).should be_a Gmail::Mailbox
      subject.instance_variable_get(:@gmail).should be_a Gmail::Client::Base
      subject.instance_variable_get(:@uid).should eq uid
      subject.labels
    end
  end

  describe "mocks" do

    subject { Gmail::Message.new(double(:mailbox, name: 'INBOX'), nil) }
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
        expect(subject).to receive(:flag).with('[Gmail]/Starred').once
        subject.star!
      end
    end

    describe "#unstar!" do
      it "should unflag '[Gmail]/Starred' from itself" do
        expect(subject).to receive(:unflag).with('[Gmail]/Starred').once
        subject.unstar!
      end
    end

    describe "#spam!" do
      it "should move itself to '[Gmail]/Spam'" do
        expect(subject).to receive(:move_to).with('[Gmail]/Spam').once
        subject.spam!
      end
    end

    describe "#archive!" do
      it "should move itself to '[Gmail]/All Mail'" do
        expect(subject).to receive(:move_to).with('[Gmail]/All Mail').once
        subject.archive!
      end
    end
  end

  describe "instance methods" do

    it "should be able to set given label" do
      mock_mailbox('[Gmail]/All Mail') do |mailbox|
        mailbox.emails(:unread, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").should_not be_empty
        mailbox.emails(:unread, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").each do |em|
          em.add_label 'Awesome'
          em.add_label 'Great'
          em.labels.should include("Awesome")
          em.labels.should include("Great")
          em.labels.should include(:Inbox)
        end
      end
    end

    it "should remove a given label" do
      mock_mailbox('[Gmail]/All Mail') do |mailbox|
        mailbox.emails(:unread, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").should_not be_empty
        mailbox.emails(:unread, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").each do |em|
          em.remove_label 'Awesome'
          em.labels.should_not include("Awesome")
          em.labels.should include("Great")
          em.labels.should include(:Inbox)
          em.flags.should_not include(:Seen)
        end
      end
    end

    it "should be able to set given label with old method" do
      mock_mailbox('[Gmail]/All Mail') do |mailbox|
        mailbox.emails(:unread, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").should_not be_empty
        mailbox.emails(:unread, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").each do |em|
          em.label! 'Awesome'
          em.label! 'Great'
          em.labels.should include("Great")
          em.labels.should include("Awesome")
          em.labels.should include(:Inbox)
        end
      end
    end

    it "should remove a given label with old method" do
      mock_mailbox('[Gmail]/All Mail') do |mailbox|
        mailbox.emails(:unread, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").should_not be_empty
        mailbox.emails(:unread, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").each do |em|
          em.remove_label! 'Awesome'
          em.labels.should_not include("Awesome")
          em.labels.should include("Great")
          em.labels.should include(:Inbox)
          em.flags.should_not include(:Seen)
        end
      end
    end

    it "should be able to mark itself with given flag" do
      mock_mailbox('[Gmail]/All Mail') do |mailbox|
        mailbox.emails(:unread, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").should_not be_empty
        mailbox.emails(:unread, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").each do |em|
          em.mark(:Seen)
          em.flags.should include(:Seen)
        end
      end
    end

    it "should be able to move itself to given box" do
      mock_mailbox('[Gmail]/All Mail') do |mailbox|
        mailbox.emails(:read, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").should_not be_empty
        mailbox.emails(:read, :from => TEST_ACCOUNT[0].to_s, :subject => "Hello world!").each do |em|
          em.mark(:unread)
          em.move_to 'TEST'
          em.labels.should include('TEST')
        end
      end
    end

    it "should be able to delete itself" do
      skip
    end
  end
end

module Gmail
  class Message
    PREFETCH_ATTRS = ["UID", "ENVELOPE", "BODY.PEEK[]", "FLAGS", "X-GM-LABELS", "X-GM-MSGID", "X-GM-THRID"].freeze

    # Raised when given label doesn't exists.
    class NoLabelError < RuntimeError; end

    def initialize(mailbox, uid, _attrs = nil)
      @uid     = uid
      @mailbox = mailbox
      @gmail   = mailbox.instance_variable_get("@gmail") if mailbox # UGLY
      @_attrs  = _attrs
    end

    def uid
      @uid ||= fetch("UID")
    end

    def msg_id
      @msg_id ||= fetch("X-GM-MSGID")
    end
    alias_method :message_id, :msg_id

    def thr_id
      @thr_id ||= fetch("X-GM-THRID")
    end
    alias_method :thread_id, :thr_id

    def envelope
      @envelope ||= fetch("ENVELOPE")
    end

    def message
      @message ||= Mail.new(fetch("BODY[]"))
    end
    alias_method :raw_message, :message

    def flags
      @flags ||= fetch("FLAGS")
    end

    def labels
      @labels ||= fetch("X-GM-LABELS")
    end

    # Mark message with given flag.
    def flag(name)
      !!@gmail.mailbox(@mailbox.name) do
        @gmail.conn.uid_store(uid, "+FLAGS", [name])
        clear_cached_attributes
      end
    end

    # Unmark message.
    def unflag(name)
      !!@gmail.mailbox(@mailbox.name) do
        @gmail.conn.uid_store(uid, "-FLAGS", [name])
        clear_cached_attributes
      end
    end

    # Do commonly used operations on message.
    def mark(flag)
      case flag
      when :read    then read!
      when :unread  then unread!
      when :deleted then delete!
      when :spam    then spam!
      else
        flag(flag)
      end
    end

    # Check whether message is read
    def read?
      flags.include?(:Seen)
    end

    # Mark as read.
    def read!
      flag(:Seen)
    end

    # Mark as unread.
    def unread!
      unflag(:Seen)
    end

    # Check whether message is starred
    def starred?
      flags.include?(:Flagged)
    end

    # Mark message with star.
    def star!
      flag(:Flagged)
    end

    # Remove message from list of starred.
    def unstar!
      unflag(:Flagged)
    end

    # Marking as spam is done by adding the `\Spam` label. To undo this,
    # you just re-apply the `\Inbox` label (see `#unspam!`)
    def spam!
      add_label("\\Spam")
    end

    # Deleting is done by adding the `\Trash` label. To undo this,
    # you just re-apply the `\Inbox` label (see `#undelete!`)
    def delete!
      add_label("\\Trash")
    end

    # Archiving is done by adding the `\All Mail` label. To undo this,
    # you just re-apply the `\Inbox` label (see `#unarchive!`)
    #
    # IMAP's fetch('1:100', (X-GM-LABELS)) function does not fetch inbox, just emails labeled important?
    # http://stackoverflow.com/a/28973760
    # In my testing the currently selected mailbox is always excluded from the X-GM-LABELS results.
    # When you called conn.select() it implicitly selected 'INBOX', therefore excluding 'Inbox'
    # from the list of labels.
    # If you selected a different mailbox then you would see '\\\\Inbox' in your results:
    def archive!
      @gmail.find(message.message_id).remove_label('\Inbox')
    end

    def unarchive!
      @gmail.find(message.message_id).add_label('\Inbox')
    end
    alias_method :unspam!, :unarchive!
    alias_method :undelete!, :unarchive!

    def move_to(name, from = nil)
      add_label(name)
      @gmail.find(message.message_id).remove_label(from) if from
    end
    alias_method :move, :move_to
    alias_method :move!, :move_to
    alias_method :move_to!, :move_to

    # Use Gmail IMAP Extensions to add a Label to an email
    def add_label(name)
      @gmail.mailbox(@mailbox.name) do
        @gmail.conn.uid_store(uid, "+X-GM-LABELS", [Net::IMAP.encode_utf7(name.to_s)])
        clear_cached_attributes
      end
    end
    alias_method :label, :add_label
    alias_method :label!, :add_label
    alias_method :add_label!, :add_label

    # Use Gmail IMAP Extensions to remove a Label from an email
    def remove_label(name)
      @gmail.mailbox(@mailbox.name) do
        @gmail.conn.uid_store(uid, "-X-GM-LABELS", [Net::IMAP.encode_utf7(name.to_s)])
        clear_cached_attributes
      end
    end
    alias_method :remove_label!, :remove_label

    def inspect
      "#<Gmail::Message#{'0x%04x' % (object_id << 1)} mailbox=#{@mailbox.name}#{' uid=' + @uid.to_s if @uid}#{' message_id=' + @msg_id.to_s if @msg_id}>"
    end

    def as_json
      super(except: ["gmail"])
    end

    def method_missing(meth, *args, &block)
      # Delegate rest directly to the message.
      if envelope.respond_to?(meth)
        envelope.send(meth, *args, &block)
      elsif message.respond_to?(meth)
        message.send(meth, *args, &block)
      else
        super
      end
    end

    def respond_to?(meth, *args, &block)
      return true if envelope.respond_to?(meth) || message.respond_to?(meth)
      super(meth, *args, &block)
    end

    def respond_to_missing?(meth, include_private = false)
      envelope.respond_to?(meth) || message.respond_to?(meth) || super
    end

    private

    def clear_cached_attributes
      @_attrs   = nil
      @msg_id   = nil
      @thr_id   = nil
      @envelope = nil
      @message  = nil
      @flags    = nil
      @labels   = nil
    end

    def fetch(value)
      @_attrs ||= begin
        @gmail.mailbox(@mailbox.name) do
          @gmail.conn.uid_fetch(uid, PREFETCH_ATTRS)[0]
        end
      end
      @_attrs.attr[value]
    end
  end # Message
end # Gmail

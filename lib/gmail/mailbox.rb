module Gmail
  class Mailbox
    MAILBOX_ALIASES = {
      :all       => ['ALL'],
      :seen      => ['SEEN'],
      :unseen    => ['UNSEEN'],
      :read      => ['SEEN'],
      :unread    => ['UNSEEN'],
      :flagged   => ['FLAGGED'],
      :unflagged => ['UNFLAGGED'],
      :starred   => ['FLAGGED'],
      :unstarred => ['UNFLAGGED'],
      :deleted   => ['DELETED'],
      :undeleted => ['UNDELETED'],
      :draft     => ['DRAFT'],
      :undrafted => ['UNDRAFT']
    }.freeze

    attr_reader :name
    attr_reader :encoded_name

    def initialize(gmail, name = "INBOX")
      @name = Net::IMAP.decode_utf7(name)
      @encoded_name = Net::IMAP.encode_utf7(name)
      @gmail = gmail
    end

    def fetch_uids(*args)
      args << :all if args.empty?

      if args.first.is_a?(Symbol)
        search = MAILBOX_ALIASES[args.shift].dup
        opts = args.first.is_a?(Hash) ? args.first : {}

        opts[:after]      and search.concat ['SINCE', Net::IMAP.format_date(opts[:after])]
        opts[:before]     and search.concat ['BEFORE', Net::IMAP.format_date(opts[:before])]
        opts[:on]         and search.concat ['ON', Net::IMAP.format_date(opts[:on])]
        opts[:from]       and search.concat ['FROM', opts[:from]]
        opts[:to]         and search.concat ['TO', opts[:to]]
        opts[:subject]    and search.concat ['SUBJECT', opts[:subject]]
        opts[:label]      and search.concat ['LABEL', opts[:label]]
        opts[:attachment] and search.concat ['HAS', 'attachment']
        opts[:search]     and search.concat ['BODY', opts[:search]]
        opts[:body]       and search.concat ['BODY', opts[:body]]
        opts[:uid]        and search.concat ['UID', opts[:uid]]
        opts[:gm]         and search.concat ['X-GM-RAW', opts[:gm]]
        opts[:message_id] and search.concat ['X-GM-MSGID', opts[:message_id].to_s]
        opts[:query]      and search.concat opts[:query]

        @gmail.mailbox(name) do
          @gmail.conn.uid_search(search)
        end
      elsif args.first.is_a?(Hash)
        fetch_uids(:all, args.first)
      else
        raise ArgumentError, "Invalid search criteria"
      end
    end

    # Returns list of emails which meets given criteria.
    #
    # ==== Examples
    #
    #   gmail.inbox.emails(:all)
    #   gmail.inbox.emails(:unread, :from => "friend@gmail.com")
    #   gmail.inbox.emails(:all, :after => Time.now-(20*24*3600))
    #   gmail.mailbox("Test").emails(:read)
    #
    #   gmail.mailbox("Test") do |box|
    #     box.emails(:read)
    #     box.emails(:unread) do |email|
    #       ... do something with each email...
    #     end
    #   end
    def emails(*args, &block)
      fetch_uids(*args).collect do |uid|
        message = Message.new(self, uid)
        yield(message) if block_given?
        message
      end
    end
    alias :search :emails
    alias :find :emails

    def emails_in_batches(*args, &block)
      return [] unless uids.is_a?(Array) && uids.any?

      uids.each_slice(100).flat_map do |slice|
        find_for_slice(slice, &block)
      end
    end

    alias :search_in_batches :emails_in_batches
    alias :find_in_batches :emails_in_batches

    # This is a convenience method that really probably shouldn't need to exist,
    # but it does make code more readable, if seriously all you want is the count
    # of messages.
    #
    # ==== Examples
    #
    #   gmail.inbox.count(:all)
    #   gmail.inbox.count(:unread, :from => "friend@gmail.com")
    #   gmail.mailbox("Test").count(:all, :after => Time.now-(20*24*3600))
    def count(*args)
      emails(*args).size
    end

    # This permanently removes messages which are marked as deleted
    def expunge
      @gmail.mailbox(name) { @gmail.conn.expunge }
    end

    def wait(options = {}, &block)
      loop do
        wait_once(options, &block)
      end
    end

    def wait_once(options = {})
      options[:idle_timeout] ||= 29 * 60

      response = nil
      loop do
        complete_cond = @gmail.conn.new_cond
        complete_now = false

        @gmail.conn.idle do |resp|
          if resp.is_a?(Net::IMAP::ContinuationRequest) && resp.data.text == 'idling'
            Thread.new do
              @gmail.conn.synchronize do
                complete_cond.wait(options[:idle_timeout]) unless complete_now
                @gmail.conn.idle_done
              end
            end
          elsif resp.is_a?(Net::IMAP::UntaggedResponse) && resp.name == 'EXISTS'
            response = resp

            @gmail.conn.synchronize do
              complete_now = true
              complete_cond.signal
            end
          end
        end

        break if response
      end

      yield response if block_given?

      nil
    end

    def inspect
      "#<Gmail::Mailbox#{'0x%04x' % (object_id << 1)} name=#{name}>"
    end

    def to_s
      name
    end

    MAILBOX_ALIASES.each_key do |mailbox|
      define_method(mailbox) do |*args, &block|
        emails(mailbox, *args, &block)
      end
    end

  private

    def find_for_slice(slice, &block)
      @gmail.conn.uid_fetch(slice, Message::PREFETCH_ATTRS).map do |data|
        message = Message.new(self, nil, data)
        yield(message) if block_given?
        message
      end
    end
  end # Message
end # Gmail

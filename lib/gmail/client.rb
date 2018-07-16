module Gmail
  module Client
    # Raised when connection with Gmail IMAP service couldn't be established.
    class ConnectionError < SocketError; end
    # Raised when given username or password are invalid.
    class AuthorizationError < Net::IMAP::NoResponseError; end
    # Raised when delivered email is invalid.
    class DeliveryError < ArgumentError; end
    # Raised when given client is not registered
    class UnknownClient < ArgumentError; end
    # Raised when email not found
    class EmailNotFound < ArgumentError; end

    def self.clients
      @clients ||= {}
    end

    def self.register(name, klass)
      clients[name] = klass
    end

    def self.new(name, *args)
      if client = clients[name]
        return client.new(*args)
      end
      raise UnknownClient, "No such client: #{name}"
    end

    require 'gmail/imap_extensions'
    require 'gmail/client/base'
    require 'gmail/client/plain'
    require 'gmail/client/xoauth'
    require 'gmail/client/xoauth2'
  end # Client
end # Gmail

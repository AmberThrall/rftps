# frozen_string_literal: true

require_relative '../rftps'
require_relative 'verb'
require_relative 'verbs_mixin'

module PI
  # Handles the underlying connection with clients. Used by PI::Client
  class BaseClient
    include VerbsMixin
    BUFFER_SIZE = 2056
    RECVFROM_SIZE = 20

    attr_reader :addrinfo, :verb_history

    def initialize(socket, addrinfo)
      @socket = socket
      @addrinfo = addrinfo
      @read_buffer = ''
      @verb_history = []
      @authenticated = false
      RFTPS.instance.register_socket(@socket, self, :update)
    end

    def message(code, message, mark: ' ')
      return unless connected?

      Logging.response "#{code}#{mark}#{message.chomp}"
      @socket.puts "#{code}#{mark}#{message.chomp}\r\n"
    rescue Errno::EPIPE, Errno::ECONNRESET
      close
    end

    def close
      RFTPS.instance.unregister_socket(@socket)
      Logging.info "Client #{@addrinfo.ip_address} disconnected"
      @socket&.close
      @socket = nil
    end

    def connected?
      !@socket.nil? && !@socket.closed?
    end

    def update
      return close unless connected?

      data = recvfrom
      return if data.nil?

      # Add the data to the buffer and see if we have a full message yet.
      @read_buffer += data.to_s

      while @read_buffer.include?("\n")
        part = @read_buffer.partition("\n")
        @read_buffer = part[2]
        handle_packet part[0].chomp
      end

      close if @read_buffer.length > BUFFER_SIZE
    end

    private

    def handle_packet(packet)
      Logging.command packet

      parts = packet.partition(' ')
      verb = parts[0].upcase
      if self.class.verbs.key? verb
        if self.class.verbs[verb].auth_only && !@authenticated
          message ResponseCodes::NOT_LOGGED_IN, 'Not logged in.'
        else
          self.class.verbs[verb].handle(self, parts[2])
        end
      else
        message ResponseCodes::COMMAND_NOT_IMPLEMENTED, "The command #{verb} is not implemented."
      end
      @verb_history.push(verb)
    end

    def recvfrom
      data, = @socket.recvfrom_nonblock(RECVFROM_SIZE)
      data
    rescue IO::WaitReadable
      nil
    rescue Errno::EPIPE, Errno::ECONNRESET
      close
    end
  end
end

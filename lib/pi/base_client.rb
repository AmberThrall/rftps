# frozen_string_literal: true

require_relative '../rftps'

module PI
  # Handles the underlying connection with clients. Used by PI::Client
  class BaseClient
    BUFFER_SIZE = 2056
    RECVFROM_SIZE = 20

    attr_reader :addrinfo

    def initialize(socket, addrinfo)
      @socket = socket
      @addrinfo = addrinfo
      @read_buffer = ''
    end

    def puts(message)
      return unless connected?

      @socket.puts message
    rescue Errno::EPIPE, Errno::ECONNRESET
      close
    end

    def close
      Logging.info "Client #{@addrinfo.ip_address} disconnected"
      @socket.close
      @socket = nil
    end

    def connected?
      !@socket.nil?
    end

    def update
      data = recvfrom
      return if data.nil?

      close if data.empty?

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
      Logging.debug packet
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

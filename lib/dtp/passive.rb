# frozen_string_literal: true

require_relative '../rftps'
require_relative 'base'

module DTP
  # Active data connection via PASV
  class Passive < Base
    attr_reader :port

    def initialize(client)
      super client
      @socket = Socket.new(Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
      @connection = nil
    end

    def listen(port_min, port_max, host: '0.0.0.0', attempts: -1)
      @port = port_min

      loop do
        sockaddr = Socket.sockaddr_in(@port, host)
        @socket.bind(sockaddr)
        @socket.listen(1)
        RFTPS.instance.register_socket(@socket, self, :try_accept)
        return @port
      rescue Errno::EADDRINUSE
        @port += 1
        attempts -= 1 if @port > port_max
        @port = port_min if @port > port_max
        return nil if attempts.zero?
      end
    end

    def connected?
      !@connection.nil? && !@connection.closed?
    end

    def try_accept
      begin
        new_socket, addrinfo = @socket.accept_nonblock
      rescue IO::WaitReadable
        return nil
      end

      return new_socket.close if connected?

      @connection = new_socket
      Logging.info "New data connection from #{addrinfo.ip_address}"
    end

    protected

    def send_impl(packet)
      try_accept unless connected?
      unless connected?
        @client.message PI::ResponseCodes::CANT_OPEN_CONNECTION, 'Nobody connected to passive data connection.'
        return -1
      end

      @connection.send packet.to_s, 0
    rescue StandardError
      @client.message PI::ResponseCodes::CONNECTION_CLOSED, 'Data connection was broken.'
      -1
    end

    def recv_impl
      try_accept unless connected?
      unless connected?
        @client.message PI::ResponseCodes::CANT_OPEN_CONNECTION, 'Nobody connected to passive data connection.'
        return -1
      end

      @connection.recv(Config.data_connections.chunk_size)
    rescue StandardError
      @client.message PI::ResponseCodes::CONNECTION_CLOSED, 'Data connection was broken.'
      -1
    end

    def close_impl
      RFTPS.instance.unregister_socket(@socket)
      @connection&.close
      @socket&.close
      @connection = nil
    end
  end
end

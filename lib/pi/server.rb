# frozen_string_literal: true

require_relative '../rftps'

module PI
  # Server for protocol communication
  class Server
    ACCEPT_BACKLOG = 10
    SELECT_TIMEOUT = 1

    def initialize
      @socket = Socket.new(Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
      @clients = {}
    end

    def listen(port, host = '0.0.0.0')
      Logging.info "Opening server on #{host}:#{port}"
      sockaddr = Socket.sockaddr_in(port, host)
      @socket.bind(sockaddr)
      @socket.listen(ACCEPT_BACKLOG)
    end

    def listening?
      !@socket.nil? && !@socket.closed?
    end

    def close
      Logging.info 'Shutting down server...'
      @clients.each { |_, client| client.close }
      @socket.close
    end

    def main_loop
      until @socket.closed?
        @clients.delete_if { |_, client| !client.connected? }
        readables, = IO.select(@clients.keys << @socket, [], [], SELECT_TIMEOUT)
        next if readables.nil?

        readables.each do |sock|
          try_accept if sock == @socket
          @clients[sock].update unless sock == @socket
        end
      end
    end

    private

    def try_accept
      begin
        new_socket, addrinfo = @socket.accept_nonblock
      rescue IO::WaitReadable, Errno::EINTR
        return
      end

      new_client = Client.new(new_socket, addrinfo)
      @clients[new_socket] = new_client

      new_client.message ResponseCodes::SERVICE_READY, Config.server.login_message

      Logging.info "New connection from #{new_client.addrinfo.ip_address}"
    end
  end
end

# frozen_string_literal: true

require_relative '../rftps'

module PI
  # Server for protocol communication
  class Server
    ACCEPT_BACKLOG = 10

    def initialize
      @socket = Socket.new(Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
      @clients = {}
    end

    def listen(port, host = '0.0.0.0')
      Logging.info "Opening server on #{host}:#{port}"
      sockaddr = Socket.sockaddr_in(port, host)
      @socket.bind(sockaddr)
      @socket.listen(ACCEPT_BACKLOG)
      RFTPS.instance.register_socket(@socket, self, :update)
    end

    def listening?
      !@socket.nil? && !@socket.closed?
    end

    def close
      RFTPS.instance.unregister_socket(@socket)
      Logging.info 'Shutting down server...' if listening?
      @clients.each { |_, client| client.close }
      @socket&.close
    end

    def update
      if listening?
        remove_disconnected
        try_accept
      else
        close
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

    def remove_disconnected
      @clients.delete_if { |_, client| !client.connected? }
    end
  end
end

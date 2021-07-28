# frozen_string_literal: true

require_relative '../rftps'
require_relative 'base'

module DTP
  # Active data connection via PORT
  class Active < Base
    def initialize(client, ip, port)
      super client
      @ip = ip
      @port = port
      @socket = nil
    end

    def connected?
      !@socket.nil? && !@socket.closed?
    end

    protected

    def send_impl(packet)
      connect unless connected?
      unless connected?
        @client.message PI::ResponseCodes::CANT_OPEN_CONNECTION, "Couldn't connect to #{@ip}:#{@port}."
        return -1
      end

      sent = @socket.send packet, 0
      @client.message PI::ResponseCodes::CONNECTION_CLOSED, 'Data connection was broken.' if sent.zero?
      sent
    rescue WaitReadable
      ret = IO.select([@socket], nil, nil, Config.data_connections.connection_timeout)
      if ret.nil?
        @client.message PI::ResponseCodes::CONNECTION_CLOSED, 'Data connection was broken.'
        return -1
      end
      retry
    rescue StandardError
      @client.message PI::ResponseCodes::CONNECTION_CLOSED, 'Data connection was broken.'
      -1
    end

    def close_impl
      @socket&.close
      @socket = nil
    end

    private

    def connect
      @socket = case Config.data_connections.active.connect_timeout
                when ..0 then Socket.tcp(@ip, @port)
                else Socket.tcp(@ip, @port, connect_timeout: Config.data_connections.active.connect_timeout)
                end
    rescue Errno::ETIMEDOUT
      @socket = nil
      Logging.info "Failed to connect to #{@ip}:#{@port}" unless connected?
    end
  end
end

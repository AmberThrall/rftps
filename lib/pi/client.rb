# frozen_string_literal: true

require_relative 'base_client'

module PI
  # Handles the FTP communication with a client
  class Client < BaseClient
    attr_reader :user, :authenticated

    def initialize(socket, addrinfo)
      super socket, addrinfo

      @user = nil
      @authenticated = false
    end

    def message(code, message)
      puts "#{code} #{message.chomp}\r\n"
    end
  end
end

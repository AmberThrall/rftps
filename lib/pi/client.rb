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

    ##########################
    ## Verb Implementations ##
    ##########################
    verb('QUIT', max_args: 0) do
      message ResponseCodes::CLOSING_CONNECTION, 'Goodbye.'
      close
    end

    verb('USER', min_args: 1, max_args: 1) do |user|
      Logging.debug "On USER: #{user}"
      message ResponseCodes::SUCCESS, 'Okay.'
    end
  end
end

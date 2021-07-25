# frozen_string_literal: true

require_relative 'base_client'
require_relative '../unix'

module PI
  # Handles the FTP communication with a client
  class Client < BaseClient
    attr_reader :user, :authenticated

    def initialize(socket, addrinfo)
      super socket, addrinfo

      @user = nil
      @password = ''
      @authenticated = false
    end

    ##########################
    ## Verb Implementations ##
    ##########################
    verb('ACCT', min_args: 1, max_args: 1) do |user|
      if @verb_history.last == 'PASS'
        @user = Unix.user(user) if Unix.user?(user)
        try_login
      else
        message ResponseCodes::BAD_COMMAND_SEQ, 'Bad sequence of commands.'
        deauthenticate
      end
    end

    verb('PASS', max_args: 1) do |pass|
      @password = pass

      if @verb_history.last == 'USER'
        try_login
      else
        message ResponseCodes::NEED_ACCT, 'ACCT request needed.'
      end
    end

    verb('QUIT', max_args: 0) do
      message ResponseCodes::CLOSING_CONNECTION, 'Goodbye.'
      close
    end

    verb('USER', min_args: 1, max_args: 1) do |user|
      deauthenticate
      @user = Unix.user(user) if Unix.user?(user)

      if Utils.valid_login?(@user, @password)
        on_logged_in
      else
        message ResponseCodes::USER_OKAY_NEED_PASS, "Password required for user #{user}"
      end
    end

    private

    def try_login
      if Utils.valid_login?(@user, @password)
        on_logged_in
      else
        message ResponseCodes::NOT_LOGGED_IN, 'Invalid username/password combination.'
        deauthenticate
      end
    end

    def deauthenticate
      @authenticated = false
      @user = nil
      @password = ''
    end

    def on_logged_in
      if @authenticated
        message ResponseCodes::COMMAND_NOT_IMPLEMENTED_BUT_OKAY, "Already logged into #{@user}."
      else
        Logging.info "Client #{addrinfo.ip_address} logged into #{@user}."
        message ResponseCodes::LOGGED_IN, "Logged into #{@user}."
      end
      @authenticated = true
    end
  end
end

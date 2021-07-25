# frozen_string_literal: true

require_relative 'base_client'
require_relative '../unix'

module PI
  # Handles the FTP communication with a client
  class Client < BaseClient
    attr_reader :user, :authenticated, :pwd

    def initialize(socket, addrinfo)
      super socket, addrinfo

      @pwd = Pathname.new('/')
      @user = nil
      @password = ''
      @authenticated = false
      @data_connection = nil
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

    verb('CDUP', auth_only: true, max_args: 0) do
      verb_CWD('..')
    end

    verb('CWD', auth_only: true, max_args: 1, split_args: false) do |path|
      pn = Pathname.new Utils.local_path_to_real_path(path, @pwd, @user)
      if pn.exist?
        pn = pn.realpath
        pn = pn.split[0] unless pn.directory?
        @pwd = pn.to_s
        message ResponseCodes::OKAY, 'Okay.'
      else
        message ResponseCodes::OKAY, "#{path}: No such file or directory."
      end
    end

    verb('FEAT', max_args: 0) do
      msg = 'Commands supported:'
      msg += self.class.verbs.keys.join("\r\n ")
      message ResponseCodes::SYSTEM_STATUS, msg, mark: '-'
      message ResponseCodes::SYSTEM_STATUS, 'END'
    end

    verb('LIST', auth_only: true) do |args|
      if @data_connection.nil?
        return message ResponseCodes::CANT_OPEN_CONNECTION, 'Please establish a connection with PASV or PORT first.'
      end

      @data_connection.send "Hello World\r\n"
    end

    verb('PASS', max_args: 1) do |pass|
      @password = pass

      if @verb_history.last == 'USER'
        try_login
      else
        message ResponseCodes::NEED_ACCT, 'ACCT request needed.'
      end
    end

    verb('PORT', auth_only: true, min_args: 6, max_args: 6, arg_sep: ',') do |*h, p1, p2|
      ip = h.join('.')
      port = p1.to_i * 256 + p2.to_i
      @data_connection&.close
      @data_connection = DTP::Active.new(self, ip, port)
      message ResponseCodes::SUCCESS, 'Okay.'
    end

    verb('PWD', auth_only: true, max_args: 0) do
      local_path = Utils.real_path_to_local_path(@pwd, @user)
      message ResponseCodes::PATHNAME_CREATED, "\"#{local_path}\""
    end

    verb('QUIT', max_args: 0) do
      message ResponseCodes::CLOSING_CONNECTION, 'Goodbye.'
      close
    end

    verb('SYST', max_args: 0) do
      message ResponseCodes::SYSTEM_TYPE, 'UNIX Type: L8'
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

    verb('XCUP', auth_only: true, max_args: 0) { verb_CDUP }
    verb('XCWD', auth_only: true, max_args: 1, split_args: false) { |path| verb_CWD(path) }
    verb('XPWD', auth_only: true, max_args: 0) { verb_PWD }

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
      @pwd = @user.home
    end
  end
end

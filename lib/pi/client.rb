# frozen_string_literal: true

require_relative 'base_client'
require_relative '../unix'
require 'sys/filesystem'

module PI
  # Handles the FTP communication with a client
  class Client < BaseClient
    attr_reader :user, :authenticated, :pwd, :root

    def initialize(socket, addrinfo)
      super socket, addrinfo

      @pwd = '/'
      @root = '/'
      @user = nil
      @password = ''
      @authenticated = false
      @data_connection = nil
      @binary_flag = true
      @rnfr = ''
      @start_position = 0
    end

    ##########################
    ## Verb Implementations ##
    ##########################
    # Missing verbs: ABOR, ADAT, CCC, CONF, CSID, ENC, EPRT, EPRT, EPSV, HOST, LANG, LPRT
    #                LPSV, MDTM, MFCT, MFF, MFMT, MIC, MLSD, MLST, OPTS, PBSZ, PROT, REIN, SITE
    #                SIZE, SMNT, SPSV, THMB, XRCP, XRSQ, XSEM, XSEN

    verb('ACCT', min_args: 1, max_args: 1) do |user|
      if @verb_history.last == 'PASS'
        @user = Unix.user(user) if Unix.user?(user)
        try_login
      else
        message ResponseCodes::BAD_COMMAND_SEQ, 'Bad sequence of commands.'
        deauthenticate
      end
    end

    verb('ALLO') do
      message ResponseCodes::COMMAND_NOT_IMPLEMENTED_BUT_OKAY, 'ALLO is obsolete.'
    end

    verb('AVBL', max_args: 1, split_args: false) do |arg|
      path = convert_path(arg)
      mountpoint = Sys::Filesystem.mount_point(path)
      stat = Sys::Filesystem.stat(mountpoint)
      message ResponseCodes::FILE_STATUS, stat.blocks_free.to_s
    rescue StandardError
      message ResponseCodes::FILE_UNAVAILABLE, 'Failed.'
    end

    verb('APPE', auth_only: true, min_args: 1, max_args: 1, split_args: false) do |arg|
      if @data_connection.nil?
        return message ResponseCodes::CANT_OPEN_CONNECTION, 'Please establish a connection with PASV or PORT first.'
      end

      dir, filename = File.split(arg)
      dir = convert_path(dir)
      return message ResponseCodes::FILE_UNAVAILABLE, "#{arg}: Directory does not exist." if dir.nil? || !File.directory?(dir)

      path = File.join(dir, filename)
      return message ResponseCodes::FILE_UNAVAILABLE, "#{arg} is a directory." if File.directory?(path)

      message ResponseCodes::FILE_STATUS_OKAY_OPENING_DATA_CONNECTION, 'Waiting for file'
      @data_connection.recv_file(path, true)
      @start_position = 0
    end

    verb('CDUP', auth_only: true, max_args: 0) do
      verb_CWD('..')
    end

    verb('CWD', auth_only: true, max_args: 1, split_args: false) do |path|
      path = '/' if path.to_s.empty?
      path = Utils.santize_path(path)
      new_pwd = RFTPS.instance.do_as(@user, @pwd) do
        path = File.realpath(path)
        path = File.split(path)[0] unless File.directory?(path)
        File.join('/', path)
      rescue Errno::ENOENT, Errno::EACCES
        nil
      end

      return message ResponseCodes::FILE_UNAVAILABLE, "#{path}: No such file or directory." if new_pwd.empty?

      @pwd = new_pwd
      message ResponseCodes::OKAY, 'Okay.'
    end

    verb('DELE', auth_only: true, max_args: 1, split_args: false) do |arg|
      path = Utils.santize_path(arg)
      RFTPS.instance.do_as(@user, @pwd) do
        File.delete(path)
        message ResponseCodes::OKAY, 'Okay.'
      rescue StandardError, Errno::ENOENT, Errno::EACCES
        message ResponseCodes::FILE_UNAVAILABLE, 'Failed.'
      end
    end

    verb('DSIZ', auth_only: true, max_args: 1, split_args: false) do |arg|
      path = Utils.santize_path(arg)
      RFTPS.instance.do_as(@user, @pwd) do
        return message ResponseCodes::FILE_UNAVAILABLE, "#{arg}: Is not a directory." unless File.directory?(path)

        size = Dir["#{path}/**/*"].select { |f| File.file?(f) }.sum { |f| File.size(f) }
        message ResponseCodes::FILE_STATUS, size.to_s
      rescue StandardError
        Logging.debug e.message
        message ResponseCodes::FILE_UNAVAILABLE, 'Failed.'
      end
    end

    verb('FEAT', max_args: 0) do
      msg = "Requests supported:\r\n"
      msg += self.class.verbs.keys.join("\r\n")
      message ResponseCodes::SYSTEM_STATUS, msg, mark: '-'
      message ResponseCodes::SYSTEM_STATUS, 'END'
    end

    verb('HELP', max_args: 1) do |verb|
      return verb_FEAT if verb.nil?
      return message ResponseCodes::COMMAND_NOT_IMPLEMENTED, "Unknown command #{verb.upcase}." unless self.class.verbs.key?(verb.upcase)

      message ResponseCodes::HELP_MESSAGE, self.class.verbs[verb.upcase].help
    end

    verb('LIST', auth_only: true, max_args: 1, split_args: false) do |arg|
      if @data_connection.nil?
        return message ResponseCodes::CANT_OPEN_CONNECTION, 'Please establish a connection with PASV or PORT first.'
      end

      path = convert_path(arg)
      return message ResponseCodes::FILE_UNAVAILABLE, "#{arg}: No such file or directory." if path.nil?

      s = Utils.ls(path, hide_dot_files: Config.server.hide_dot_files)
      @data_connection.send_ascii s
    end

    verb('MKD', auth_only: true, max_args: 1, split_args: false) do |arg|
      path = Utils.santize_path(arg)
      RFTPS.instance.do_as(@user, @pwd) do
        Dir.mkdir(path)
        message ResponseCodes::PATHNAME_CREATED, "\"#{File.realpath(path)}\""
      rescue Errno::EACCES
        message ResponseCodes::FILE_UNAVAILABLE, 'Access denied.'
      rescue StandardError, Errno::ENOENT
        message ResponseCodes::FILE_UNAVAILABLE, 'Failed.'
      end
    end

    verb('MODE', auth_only: true, max_args: 1) do |arg|
      message ResponseCodes::SUCCESS, 'Okay.' if arg.upcase == 'S'
      message ResponseCodes::COMMAND_NOT_IMPLEMENTED_FOR_PARAMETER, 'Invalid parameter.' unless arg.upcase == 'S'
    end

    verb('NLST', auth_only: true, max_args: 1, split_args: false) do |arg|
      if @data_connection.nil?
        return message ResponseCodes::CANT_OPEN_CONNECTION, 'Please establish a connection with PASV or PORT first.'
      end

      path = convert_path(arg)
      return message ResponseCodes::FILE_UNAVAILABLE, "#{arg}: No such file or directory." if path.nil?

      files = File.directory?(path) ? Dir.children(path) : File.split(files).drop(1)
      files.delete_if { |x| x[0] == '.' } if Config.server.hide_dot_files
      @data_connection.send_ascii "#{files.join("\r\n")}\r\n"
    end

    verb('NOOP', max_args: 0) do
      message ResponseCodes::SUCCESS, "Okay."
    end

    verb('PASS', max_args: 1) do |pass|
      @password = pass

      if @verb_history.last == 'USER'
        try_login
      else
        message ResponseCodes::NEED_ACCT, 'ACCT request needed.'
      end
    end

    verb('PASV', auth_only: true, max_args: 0) do
      @data_connection&.close
      @data_connection = DTP::Passive.new(self)
      port = @data_connection.listen(Config.data_connections.passive.port_range.min, Config.data_connections.passive.port_range.max, host: Config.server.host, attempts: 1)

      if port.nil?
        @data_connection = nil
        Logging.error 'Couldn\'t open passive data connection, all ports in use.'
        return message ResponseCodes::CANT_OPEN_CONNECTION, 'Couldn\'t open passive data connection, all ports in use. Feel free to try again.'
      end

      Logging.info "Opened passive data connection on port #{port}."
      p2 = port % 256
      p1 = port / 256
      message ResponseCodes::ENTERING_PASV_MODE, "#{Config.server.external_ip.gsub('.', ',')},#{p1},#{p2}"
    end

    verb('PORT', auth_only: true, min_args: 6, max_args: 6, arg_sep: ',') do |*h, p1, p2|
      ip = h.join('.')
      port = p1.to_i * 256 + p2.to_i
      @data_connection&.close
      @data_connection = DTP::Active.new(self, ip, port)
      message ResponseCodes::SUCCESS, 'Okay.'
    end

    verb('PWD', auth_only: true, max_args: 0) do
      message ResponseCodes::PATHNAME_CREATED, "\"#{@pwd}\""
    end

    verb('QUIT', max_args: 0) do
      message ResponseCodes::CLOSING_CONNECTION, 'Goodbye.'
      close
      deauthenticate
    end

    verb('REST', auth_only: true, max_args: 1) do |arg|
      @start_position = arg.to_s
      message ResponseCodes::REQUESTED_FILE_ACTION_PENDING, "Start position set to #{@start_position}."
    end

    verb('RETR', auth_only: true, min_args: 1, max_args: 1, split_args: false) do |arg|
      if @data_connection.nil?
        return message ResponseCodes::CANT_OPEN_CONNECTION, 'Please establish a connection with PASV or PORT first.'
      end

      path = convert_path(arg)
      return message ResponseCodes::FILE_UNAVAILABLE, "#{arg}: No such file or directory." if path.nil?
      return message ResponseCodes::FILE_UNAVAILABLE, "#{arg} is a directory." unless File.file?(path)

      message ResponseCodes::FILE_STATUS_OKAY_OPENING_DATA_CONNECTION, 'Sending file'
      @data_connection.send_file path, @start_position
      @start_position = 0
    end

    verb('RMD', auth_only: true, max_args: 1, split_args: false) do |arg|
      path = Utils.santize_path(arg)
      RFTPS.instance.do_as(@user, @pwd) do
        Dir.rmdir(path)
        message ResponseCodes::OKAY, 'Okay.'
      rescue StandardError, Errno::ENOENT, Errno::EACCES
        message ResponseCodes::FILE_UNAVAILABLE, 'Failed.'
      end
    end

    verb('RMDA', auth_only: true, max_args: 1, split_args: false) do |arg|
      path = Utils.santize_path(arg)
      RFTPS.instance.do_as(@user, @pwd) do
        FileUtils.remove_dir(path)
        message ResponseCodes::OKAY, 'Okay.'
      rescue StandardError, Errno::ENOENT, Errno::EACCES
        message ResponseCodes::FILE_UNAVAILABLE, 'Failed.'
      end
    end

    verb('RNFR', auth_only: true, max_args: 1, split_args: false) do |arg|
      @rnfr = Utils.santize_path(arg)
      message ResponseCodes::REQUESTED_FILE_ACTION_PENDING, 'Waiting for RNTO...'
    end

    verb('RNTO', auth_only: true, max_args: 1, split_args: false) do |arg|
      return message ResponseCodes::BAD_COMMAND_SEQ, 'Bad sequence of commands.' unless @verb_history.last == 'RNFR'

      rnto = Utils.santize_path(arg)
      RFTPS.instance.do_as(@user, @pwd) do
        FileUtils.mv(@rnfr, rnto)
        message ResponseCodes::OKAY, 'Okay.'
      rescue StandardError, Errno::ENOENT, Errno::EACCES
        message ResponseCodes::FILE_UNAVAILABLE, 'Failed.'
      end
    end

    verb('STAT', max_args: 0) do
      s = "FTP server status:\r\n"
      s += "Version #{RFTPS.version}\r\n"
      s += "Connected to #{Config.server.external_ip}\r\n"
      s += "Logged into #{@user}\r\n" if @authenticated
      s += "Not logged in\r\n" unless @authenticated
      s += "TYPE: #{@binary_flag ? 'BINARY' : 'ASCII'},"
      s += " FORM: Nonprint; STRUcture: File; transfer MODE: Stream\r\n"
      s += 'No data connection' if @data_connection.nil?
      s += @data_connection.status unless @data_connection.nil?
      message ResponseCodes::SYSTEM_STATUS, s, mark: '-'
      message ResponseCodes::SYSTEM_STATUS, 'End of status'
    end

    verb('STOR', auth_only: true, min_args: 1, max_args: 1, split_args: false) do |arg|
      if @data_connection.nil?
        return message ResponseCodes::CANT_OPEN_CONNECTION, 'Please establish a connection with PASV or PORT first.'
      end

      dir, filename = File.split(arg)
      dir = convert_path(dir)
      return message ResponseCodes::FILE_UNAVAILABLE, "#{arg}: Directory does not exist." if dir.nil? || !File.directory?(dir)

      path = File.join(dir, filename)
      return message ResponseCodes::FILE_UNAVAILABLE, "#{arg} is a directory." if File.directory?(path)

      message ResponseCodes::FILE_STATUS_OKAY_OPENING_DATA_CONNECTION, 'Waiting for file'
      @data_connection.recv_file(path, false)
      @start_position = 0
    end

    verb('STOU', auth_only: true, max_args: 1, split_args: false) do |arg|
      if @data_connection.nil?
        return message ResponseCodes::CANT_OPEN_CONNECTION, 'Please establish a connection with PASV or PORT first.'
      end

      arg ||= 'file'
      dir, filename = File.split(arg)
      dir = convert_path(dir)
      dir = convert_path('.') if dir.nil? || !File.directory?(dir)

      path = File.join(dir, filename)
      n = 1
      while File.exist?(path)
        path = File.join(dir, "#{filename}.#{n}")
        n += 1
      end

      message ResponseCodes::FILE_STATUS_OKAY_OPENING_DATA_CONNECTION, "\"#{Utils.global_path_to_local(path, @root)}\""
      @data_connection.recv_file(path, false)
      @start_position = 0
    end

    verb('STRU', auth_only: true, max_args: 1) do |arg|
      message ResponseCodes::SUCCESS, 'Okay.' if arg.upcase == 'F'
      message ResponseCodes::COMMAND_NOT_IMPLEMENTED_FOR_PARAMETER, 'Invalid parameter.' unless arg.upcase == 'F'
    end

    verb('SYST', max_args: 0) do
      message ResponseCodes::SYSTEM_TYPE, 'UNIX Type: L8'
    end

    verb('TYPE', max_args: 1, split_args: false) do |flag|
      if ['A', 'A N', 'I', 'L 8'].include?(flag.upcase)
        @binary_flag = ['I', 'L 8'].include?(flag.upcase)
        message ResponseCodes::SYSTEM_TYPE, 'Okay.'
      else
        message ResponseCodes::COMMAND_NOT_IMPLEMENTED_FOR_PARAMETER, "Unsupported parameter #{flag}."
      end
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

    verb_synonym('XCUP', 'CDUP')
    verb_synonym('XCWD', 'CWD')
    verb_synonym('XMKD', 'MKD')
    verb_synonym('XPWD', 'PWD')
    verb_synonym('XRMD', 'RMD')

    private

    def convert_path(path)
      path ||= '.'
      path = path[1..-2] if path.length > 1 && ((path[0] == '\'' && path[-1] == '\'') || (path[0] == '"' && path[-1] == '"'))
      new_path = RFTPS.instance.do_as(@user, @pwd) do
        File.realpath(path)
      rescue Errno::ENOENT, Errno::EACCES
        nil
      end
      return nil if new_path.empty?

      File.join(@root, new_path)
    end

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
      @pwd = '/'
      @root = '/'
    end

    def on_logged_in
      if @authenticated
        message ResponseCodes::COMMAND_NOT_IMPLEMENTED_BUT_OKAY, "Already logged into #{@user}."
      else
        Logging.info "Client #{addrinfo.ip_address} logged into #{@user}."
        message ResponseCodes::LOGGED_IN, "Logged into #{@user}."
      end
      @authenticated = true
      @pwd = Config.users.chroot ? '/' : @user.home
      @root = Config.users.chroot ? @user.home : '/'
    end
  end
end

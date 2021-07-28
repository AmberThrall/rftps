# frozen_string_literal: true

require 'etc'

require_relative 'unix/user'
require_relative 'unix/group'
require_relative 'unix/permissions'
require_relative 'rftps'

# Enables interacting with the unix system.
module Unix
  def self.whoami?
    Unix.user(Etc.getpwuid)
  end

  def self.real_user_group
    [Unix.user(Process::Sys.getuid), Unix.group(Process::Sys.getgid)]
  end

  def self.effective_user_group
    [Unix.user(Process::Sys.geteuid), Unix.group(Process::Sys.getegid)]
  end

  def self.set_real_user_group(user = nil, group = nil)
    Process::Sys.setgid(group.is_a?(Integer) ? group : Unix.group(group).id) unless group.nil?
    Process::Sys.setuid(user.is_a?(Integer) ? user : Unix.user(user).id) unless user.nil?
  end

  def self.set_effective_user_group(user = nil, group = nil)
    Process::Sys.setegid(group.is_a?(Integer) ? group : Unix.group(group).id) unless group.nil?
    Process::Sys.seteuid(user.is_a?(Integer) ? user : Unix.user(user).id) unless user.nil?
  end

  def self.user(arg)
    case arg
    when String then User.new(Etc.getpwnam(arg))
    when Integer then User.new(Etc.getpwuid(arg))
    when User then arg
    when Etc::Passwd then User.new(arg)
    else raise 'Expected either name or uid.'
    end
  end

  def self.user?(arg)
    case arg
    when String then Etc.getpwnam(arg)
    when Integer then Etc.getpwuid(arg)
    when User then true
    when Etc::Passwd then true
    else return false
    end
    true
  rescue ArgumentError
    false
  end

  def self.group(arg)
    case arg
    when String then Group.new(Etc.getgrnam(arg))
    when Integer then Group.new(Etc.getgrgid(arg))
    when Group then arg
    when Etc::Group then Group.new(arg)
    else raise 'Expected either a name or gid.'
    end
  end

  def self.group?(arg)
    case arg
    when String then Etc.getgrnam(arg)
    when Integer then Etc.getgrgid(arg)
    when Group then true
    when Etc::Group then true
    else return false
    end
    true
  rescue ArgumentError
    false
  end

  def self.users
    users = []
    Etc.passwd do |u|
      users.push(User.new(u))
    end
    users
  end

  def self.groups
    groups = []
    Etc.group do |g|
      groups.push(Group.new(g))
    end
    groups
  end

  def self.confdir
    Etc.sysconfdir
  end

  def self.tmpdir
    Etc.systmpdir
  end

  def self.nprocessors
    Etc.nprocessors
  end

  def self.daemonize
    exit if fork
    Process.setsid
    exit if fork

    $stdin.reopen '/dev/null'
    $stdout.reopen '/dev/null', 'a'
    $stderr.reopen '/dev/null', 'a'

    Dir.chdir('/')
  end

  def self.owner(arg)
    stat = arg.is_a?(File::Stat) ? arg : File.stat(arg)
    [Unix.user(stat.uid), Unix.group(stat.gid)]
  end

  def self.chroot(path)
    Dir.chroot('.') # Escape from current chroot
    Dir.chroot(path)
  end
end

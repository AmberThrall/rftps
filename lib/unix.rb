# frozen_string_literal: true

require 'etc'

require_relative 'unix/user'
require_relative 'unix/group'

# Enables interacting with the unix system.
module Unix
  def self.whoami?
    User.new(Etc.getpwuid)
  end

  def self.user(arg)
    case arg
    when String then User.new(Etc.getpwnam(arg))
    when Integer then User.new(Etc.getpwuid(arg))
    else raise 'Expected either name or uid.'
    end
  end

  def self.group(arg)
    case arg
    when String then Group.new(Etc.getgrnam(arg))
    when Integer then Group.new(Etc.getgrgid(arg))
    else raise 'Expected either a name or gid.'
    end
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
end

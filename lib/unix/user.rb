# frozen_string_literal: true

require 'unix_crypt'
require_relative '../unix'

module Unix
  # Unix user
  class User
    attr_reader :id, :name, :group, :home

    def initialize(struct)
      @id = struct.uid
      @name = struct.name
      @passwd = struct.passwd
      @group = Unix.group(struct.gid)
      @home = struct.dir
    end

    def compare_password(password)
      actual = @passwd == 'x' ? fetch_shadow_password : @passwd

      case @passwd
      when '' then password.empty?
      when '!', '*', '*LK*', '*NP*', '!!' then false
      else UnixCrypt.valid?(password, actual)
      end
    end

    def root?
      @id.zero?
    end

    def can_login?
      !['!', '*', '*LK*', '*NP*', '!!'].includes? @passwd
    end

    def ==(other)
      case other.class
      when Unix::User then other.id == @id
      when Integer then other == @id
      when String then other == @name
      else false
      end
    end

    def to_s
      @name
    end

    private

    def fetch_shadow_password
      text = File.open("#{Unix.confdir}/shadow").read
      text.each_line do |line|
        name, encrypted_password = line.split(':')
        return encrypted_password if name == @name
      end
      raise "Couldn't determine user #{@name}'s password"
    end
  end
end

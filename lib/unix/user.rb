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
      case @passwd
      when 'x' then UnixCrypt.valid?(password, fetch_shadow_password)
      when '*' then false
      else UnixCrypt.valid?(password, @passwd)
      end
    end

    def root?
      @id.zero?
    end

    def can_login?
      @passwd != '*'
    end

    def ==(other)
      other.is_a?(Unix::User) && other.id == @id
    end

    def to_s
      @name
    end

    private

    def fetch_shadow_password
      text = File.open('/etc/shadow').read
      text.each_line do |line|
        name, encrypted_password = line.split(':')
        return encrypted_password if name == @name
      end
      raise "Couldn't determine user #{@name}'s password"
    end
  end
end

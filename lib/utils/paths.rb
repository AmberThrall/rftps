# frozen_string_literal: true

require 'pathname'

# Various utility methods
module Utils
  def self.real_path_to_local_path(path, user)
    path = Pathname.new(path)
    path = path.realpath if File.exist?(path.to_s)
    path = path.relative_path_from(user.home).to_s
    path == '.' ? '/' : "/#{path}".squeeze('/')
  end

  def self.local_path_to_real_path(path, pwd, user)
    res = "#{pwd}/#{path}"
    res = user.home if path.to_s.empty?
    res = "#{user.home}/#{path}" if path.to_s[0] == '/'
    File.expand_path(res.squeeze('/'))
  end

  def self.descendent?(path, base)
    path = File.expand_path(path).split('/')
    base = File.expand_path(base).split('/')

    path[0..base.size - 1] == base
  end
end

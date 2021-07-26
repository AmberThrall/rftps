# frozen_string_literal: true

require 'pathname'

# Various utility methods
module Utils
  def self.global_path_to_local(path, pwd)
    path = Pathname.new(path)
    path = path.realpath if File.exist?(path.to_s)
    path.relative_path_from(pwd).to_s
  rescue Errno::EACCES
    RFTPS.instance.do_as(0) { Utils.global_path_to_local(path, pwd) }
  end

  def self.local_path_to_global(path, pwd)
    return pwd if path.to_s.empty?
    return File.expand_path(path.squeeze('/')) if path[0] == '/'

    File.expand_path("#{pwd}/#{path}".squeeze('/'))
  rescue Errno::EACCES
    RFTPS.instance.do_as(0) { Utils.local_path_to_global(path, pwd) }
  end

  def self.descendent?(path, base)
    path = File.expand_path(path).split('/')
    base = File.expand_path(base).split('/')

    path[0..base.size - 1] == base
  end
end

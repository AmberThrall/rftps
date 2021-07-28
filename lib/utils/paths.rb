# frozen_string_literal: true

require 'pathname'

# Various utility methods
module Utils
  def self.global_path_to_local(path, root)
    parts = File.expand_path(path).split('/')
    base = File.expand_path(root).split('/')
    return nil if root == '/' && path[0] != '/'
    return nil if parts[0..base.size - 1] != base && !base.empty?
    
    relative_path = File.join(['/'] << parts[base.size..])

    Pathname.new(relative_path).relative_path_from(root).to_s
  rescue Errno::EACCES, Errno::ENOENT
    nil
  end

  def self.descendent?(path, base)
    path = File.expand_path(path).split('/')
    base = File.expand_path(base).split('/')

    path[0..base.size - 1] == base
  end
end

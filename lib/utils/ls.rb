# frozen_string_literal: true

require_relative '../unix'

# Various utilities
module Utils
  # Structure for /bin/ls -l <filename> format
  class LsFormat
    attr_reader :flags, :nlink, :owner, :group, :size, :mtime, :filename, :linkto

    def initialize(path = '.')
      raise StandardError, "No such file or directory '#{path}'" unless File.exist?(path)

      @flags = get_flags path
      @nlink = File.stat(path).nlink
      @owner, @group = Unix.owner(path)
      @size = File.size(path)
      @mtime = File.mtime(path).localtime
      @filename = File.split(path)[1]
      @linkto = File.symlink?(path) ? File.readlink(path) : ''
    end

    def to_s
      "#{@flags} #{@nlinks} #{@owner} #{@group} #{@size} #{@mtime_to_str} #{file_and_link_to_str}"
    end

    private

    def mtime_to_str
      @mtime.year == Time.now.year ? @mtime.strftime('%b %d %H:%M') : @mtime.strftime('%b %d %Y')
    end

    def file_and_link_to_str
      s = @filename.include?(' ') ? "'#{@filename}'" : @filename
      s += " -> #{@linkto.include?(' ') ? "'#{@linkto}'" : @linkto}" unless @linkto.empty?
      s
    end

    def get_flags(path)
      s = File.directory?(path) ? 'd' : '-'
      s = File.symlink?(path) ? 'l' : s
      s += Unix::Permissions.new(File.stat(path)).to_s
    end
  end

  # Constructor for /bin/ls -l [*args] format
  class Ls
    attr_reader :entries, :files

    def initialize(path = '.', hide_dot_files: true)
      return unless File.exist?(path)

      @files = [path]
      @files = Dir.children(path).map { |s| "#{path}/#{s}".squeeze('/') } if File.directory?(path)
      @files.delete_if { |s| File.split(s)[1][0] == '.' } if hide_dot_files
      @files.delete_if { |s| !File.exist?(s) }
      @entries = files.map { |s| LsFormat.new s }
    end

    def to_s
      s = ''
      @entries.each do |e|
        s += "#{e.flags} "
        %i[nlink owner group size].each { |sym| s += e.send(sym).to_s.rjust(max_width(sym)) << ' ' }
        s += e.mtime.year == Time.now.year ? e.mtime.strftime('%b %d %H:%M ') : e.mtime.strftime('%b %d  %Y ')
        s += e.filename.include?(' ') ? "'#{e.filename}'" : " #{e.filename}"
        s += " -> #{e.linkto.include?(' ') ? "'#{e.linkto}'" : e.linkto}" unless e.linkto.empty?
        s += "\n"
      end
      s
    end

    private

    def max_width(attr)
      @entries.map { |e| e.send(attr.to_s).to_s.length }.max
    end
  end

  def self.ls(path = '.', hide_dot_files: true)
    RFTPS.instance.do_as(0) { Ls.new(path, hide_dot_files: hide_dot_files).to_s }
  end
end

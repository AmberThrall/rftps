# frozen_string_literal: true

require 'time'
require_relative 'config'

# Module handling various logging functions
module Logging
  # Handles the actual writing of text to logs
  class Writer
    CATEGORY_WIDTH = 9

    def erase(file)
      File.open(file == :logfile ? Config.logging.file : file, 'w').close
    end

    def message(message, category, methods, timestamp)
      s = timestamp.empty? ? '' : "[#{Time.new.localtime.strftime(timestamp)}]"
      s += "[#{category}]".ljust(CATEGORY_WIDTH)
      s += ' '
      offset = ' '.ljust(s.length)
      message.each_line.with_index { |line, index| s += index.positive? ? "#{offset}#{line}" : line }
      Array(methods).each { |method| output_message(method, s) }
    end

    private

    def output_message(method, string)
      case method
      when :stdout then puts string
      when :stderr then warn string
      when :logfile then append_to_file(Config.logging.file, string)
      when String then append_to_file(method, string)
      else raise "Invalid output method #{method} for message."
      end
    end

    def append_to_file(file, string)
      f = File.open(file, 'a')
      f.puts(string)
      f.close
    rescue SystemCallError
      # skip
    end
  end

  LEVELS = {
    fatal:   { category: 'FATAL',   methods: %i[stderr logfile] },
    error:   { category: 'ERROR',   methods: %i[stderr logfile] },
    warning: { category: 'WARNING', methods: %i[stderr logfile] },
    info:    { category: 'INFO',    methods: %i[stdout logfile] },
    debug:   { category: 'DEBUG',   methods: %i[stdout logfile] }
  }.freeze

  def self.erase(target = :logfile)
    return unless Config.logging.enabled

    Writer.new.erase(target)
  end

  def self.message(level, message, category: 'MESSAGE', methods: %i[stdout logfile], timestamp: '%m/%d/%Y %H:%M:%S')
    return unless Config.logging.enabled

    Writer.new.message(message, category, methods, timestamp) unless level > Config.logging.max_level
  end

  LEVELS.each_with_index do |(key, default_opts), index|
    define_singleton_method(key) do
      |message, category: default_opts[:category], methods: default_opts[:methods], timestamp: Config.logging.timestamp|
      message(index, message, category: category, methods: methods, timestamp: timestamp)
    end
  end
end

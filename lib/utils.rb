# frozen_string_literal: true

require_relative 'utils/pretty_print'
require_relative 'utils/valid_login'
require_relative 'utils/paths'
require_relative 'utils/ls'
require_relative 'unix'
require 'net/http'
require 'resolv'

# Various utility methods
module Utils
  def self.boolean?(obj)
    [true, false].include? obj
  end

  def self.to_boolean(obj)
    obj.to_s.downcase == 'true'
  end

  def self.progress_bar(progress, total, width: 10, format: '$progress / $total $bar $percent%')
    ratio = progress / total.to_f
    ratio = 1 if ratio > 1
    nhash = (ratio * width).to_i
    s = format.gsub('$progress', progress.to_s.rjust(total.to_s.length))
    s = s.gsub('$total', total.to_s)
    s = s.gsub('$bar', +'[' << ('#' * nhash).ljust(width) << ']')
    s.gsub('$percent', (ratio * 100).to_i.to_s.rjust(3))
  end

  def self.what_is_my_ip?
    Net::HTTP.get URI 'https://api.ipify.org'
  end

  def self.ip_address?(str)
    str =~ Resolv::IPv4::Regex ? true : false
  end

  def self.format_bytes(bytes, ndigits: 2, base: 1_024, units: nil)
    units = %w[B kB MB GB TB PB EB ZB YB] if base == 1_000 && units.nil?
    units = %w[B KiB MiB GiB TiB PiB EiB ZiB YiB] if base == 1_024 && units.nil?
    units ||= ['B']
    unit = units[0]

    units[1..].each do |m|
      break if bytes < base

      unit = m
      bytes /= base.to_f
    end

    return "#{bytes.to_i} #{unit}" if ndigits <= 0 || unit == units[0]

    parts = bytes.to_s.partition('.')
    digits = parts[2][..(ndigits - 1)]
    digits += '0' * (ndigits - digits.length) if digits.length < ndigits
    "#{parts[0]}.#{digits} #{unit}"
  end
end

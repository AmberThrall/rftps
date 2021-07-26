# frozen_string_literal: true

require_relative 'utils/pretty_print'
require_relative 'utils/valid_login'
require_relative 'utils/paths'
require_relative 'utils/ls'
require_relative 'unix'

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
    s = s.gsub('$bar', +'[' << +'#' << nhash << ' ' * (width - nhash) << ']')
    s.gsub('$percent', (ratio * 100).to_i.to_s.rjust(3))
  end
end

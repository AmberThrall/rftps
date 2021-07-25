# frozen_string_literal: true

require_relative 'utils/pretty_print'
require_relative 'utils/valid_login'

# Various utility methods
module Utils
  def self.boolean?(obj)
    [true, false].include? obj
  end
end

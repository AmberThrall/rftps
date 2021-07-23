# frozen_string_literal: true

require_relative 'config'
require_relative 'logging'

begin
  require 'minitest/reporters'

  Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(color: true)]
rescue LoadError
  # skip
end

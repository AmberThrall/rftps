# frozen_string_literal: true

Dir[File.join(__dir__, 'test_*.rb')].sort.each { |file| require file }

begin
  require 'minitest/reporters'

  Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(color: true)]
rescue LoadError
  # skip
end

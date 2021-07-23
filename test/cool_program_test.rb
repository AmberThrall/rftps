# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/cool_program'

class CoolProgramTest < Minitest::Test
  def test_coolness_off_the_charts
    assert_equal CoolProgram.new.coolness, 11
  end

  def test_two
    assert_equal 2, 2
  end
end

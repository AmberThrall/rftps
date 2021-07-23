# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/unix'

class UnixTest < Minitest::Test
  def test_user
    assert Unix.user?(0)
    root = Unix.user(0)
    assert_equal root.id, 0
    assert_equal root.name, 'root'
    assert_equal root.group.id, 0
    assert_equal root.home, '/root'
  end

  def test_group
    assert Unix.group?(0)
    grp = Unix.group(0)
    assert_equal grp.id, 0
    assert_equal grp.name, 'root'
  end
end

# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/unix'

class PermissionsTest < Minitest::Test
  def test_permission_groups
    p1 = Unix::PermissionsGroup.new(true, true, false)
    p2 = Unix::PermissionsGroup.new(3)

    assert_equal p1.to_i, 6
    assert_equal p1.to_s, 'rw-'
    assert_equal p2.to_i, 3
    assert_equal p2.to_s, '-wx'
  end

  def test_permissions
    p = Unix::Permissions.new(0755)

    assert_equal p.to_i, 0755
    assert_equal p.to_s, '755'
  end
end

# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/config'
require_relative '../lib/constants'

TEST_CONFIG = %(
  [server]
  port = 5000
  max_connections = 30

  [data_connections]
  chunk_size = 1024
  connection_timeout = 600
  pasv.enabled = false
  pasv.port_range.min = 5001
  pasv.port_range.max = 5099

  [logging]
  file = "rftps.log"
  max_level = 5
)

TEST_BAD_CONFIG = %(
  [server]
  port = five-thousand
)

class ConfigTest < Minitest::Test
  def test_load
    Config.load(TEST_CONFIG)

    assert_equal Config.server.port, 5000
    assert_equal Config.server.max_connections, 30
    assert_equal Config.server.login_message, "Welcome to rftps (v#{VERSION})."
    assert_equal Config.data_connections.chunk_size, 1024
    assert_equal Config.data_connections.connection_timeout, 600
    assert_equal Config.data_connections.pasv.enabled, false
    assert_equal Config.data_connections.pasv.port_range.min, 5001
    assert_equal Config.data_connections.pasv.port_range.max, 5099
    assert_equal Config.data_connections.port.enabled, true
    assert_equal Config.logging.file, 'rftps.log'
    assert_equal Config.logging.max_level, 5
  end

  def test_defaults
    Config.load(TEST_CONFIG)
    assert_equal Config.server.port, 5000
    Config.defaults
    assert_equal Config.server.port, 21
  end

  def test_bad_config
    Config.logging.enabled = false
    Config.load(TEST_BAD_CONFIG)
    assert_equal Config.server.port, 21
  end

  def test_no_such_file
    Config.logging.enabled = false
    Config.load_file('/')
    assert_equal Config.server.port, 21
  end
end

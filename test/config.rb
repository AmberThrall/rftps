# frozen_string_literal: true

require 'pp'
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
  file = "log/rftps.log"
  level = 5
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
    assert_equal Config.logging.file, 'log/rftps.log'
    assert_equal Config.logging.level, 5
    assert_equal Config.logging.packets.log, false
    assert_equal Config.logging.packets.file, '/var/log/rftps.pcap'
  end
end

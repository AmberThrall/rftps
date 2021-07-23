# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/logging'
require_relative '../lib/config'

LOG_TEST_FILE = 'logging_test.log'
TEST_WRITE_ACTUAL = "[INFO]    Information.\n[WARNING] Warning.\n"
TEST_LEVEL_ACTUAL = "[FATAL]   Fatal.\n[WARNING] Warning.\n"
TEST_MULTILINE_ACTUAL = "[FATAL]   Line 1.\n          Line 2.\n"

class LoggingTest < Minitest::Test
  def test_write
    delete_log_if_exists
    Config.logging.file = LOG_TEST_FILE
    Config.logging.max_level = 10
    Config.logging.timestamp = ''
    Logging.info 'Information.', methods: :logfile
    Logging.warning 'Warning.', methods: :logfile
    assert_file_contents_equal TEST_WRITE_ACTUAL
    delete_log_if_exists
  end

  def test_erase
    delete_log_if_exists
    Config.logging.file = LOG_TEST_FILE
    Logging.fatal 'Message', methods: :logfile
    Logging.erase
    assert_file_contents_equal ''
    delete_log_if_exists
  end

  def test_level
    delete_log_if_exists
    Config.logging.file = LOG_TEST_FILE
    Config.logging.max_level = 2
    Config.logging.timestamp = ''
    Logging.fatal 'Fatal.', methods: :logfile
    Logging.debug 'Debug.', methods: :logfile
    Logging.warning 'Warning.', methods: :logfile
    assert_file_contents_equal TEST_LEVEL_ACTUAL
    delete_log_if_exists
  end

  def test_multiline
    delete_log_if_exists
    Config.logging.file = LOG_TEST_FILE
    Config.logging.timestamp = ''
    Logging.fatal "Line 1.\nLine 2.", methods: :logfile
    assert_file_contents_equal TEST_MULTILINE_ACTUAL
    delete_log_if_exists
  end

  def assert_file_contents_equal(actual)
    assert File.file?(LOG_TEST_FILE)
    expected = File.read(LOG_TEST_FILE)
    assert_equal expected, actual
  end

  def delete_log_if_exists
    File.delete LOG_TEST_FILE if File.file?(LOG_TEST_FILE)
  end
end

# frozen_string_literal: true

require 'optparse'
require 'pathname'
require 'fileutils'
require 'singleton'
require 'socket'

Dir[File.join(__dir__, '*.rb')].reject { |f| f[__FILE__] }.sort.each { |file| require file }

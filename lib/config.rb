# frozen_string_literal: true

require 'tomlrb'
require_relative 'config/group'
require_relative 'constants'
require_relative 'utils'

# Loads and stores various configuration settings
module Config
  @root_group = Group.new(:root)

  def self.load_file(filename)
    load(File.read(filename))
  end

  def self.load(contents)
    copy_from_hash(Tomlrb.parse(contents, symbolize_keys: true))
  end

  def self.copy_from_hash(hash)
    @root_group.copy_from_hash(hash)
  end

  def self.to_hash
    @root_group.to_hash
  end

  def self.subgroup?(name)
    @root_group.subgroup?(name)
  end

  def self.setting?(name)
    @root_group.setting?(name)
  end

  def self.group(name, &block)
    @root_group.group(name, &block)

    # Define getter
    define_singleton_method name do
      @root_group.get(name)
    end
  end

  def self.setting(name, default, &block)
    @root_group.setting(name, default, &block)

    # Define getter and setter
    define_singleton_method name do
      @root_group.set(name)
    end

    define_singleton_method "#{name}=".to_sym do |value|
      @root_group.set(name, value)
    end
  end

  #####################################
  ## Actual configuration definition ##
  #####################################
  group :server do
    setting(:port, 21) { |x| x.is_a?(Integer) && x.positive? && x <= 65_535 }
    setting(:max_connections, 0) { |x| x.is_a?(Integer) }
    setting(:login_message, "Welcome to rftps (v#{VERSION}).") { |x| x.is_a?(String) }
  end

  group :data_connections do
    setting(:chunk_size, 8_192) { |x| x.is_a?(Integer) && x.positive? }
    setting(:connection_timeout, 300) { |x| x.is_a?(Integer) && x.positive? }
    group :pasv do
      setting(:enabled, true) { |x| Utils.boolean? x }
      group :port_range do
        setting(:min, 15_000) { |x| x.is_a?(Integer) && x.positive? && x <= 65_535 }
        setting(:max, 15_100) { |x| x.is_a?(Integer) && x.positive? && x <= 65_535 }
      end
    end
    group :port do
      setting(:enabled, true) { |x| Utils.boolean? x }
    end
  end

  group :logging do
    setting(:file, '/var/log/rsftp.log') { |x| x.is_a?(String) }
    setting(:level, 0) { |x| x.is_a?(Integer) && x >= 0 }
    group :packets do
      setting(:log, false) { |x| Utils.boolean? x }
      setting(:file, '/var/log/rftps.pcap') { |x| x.is_a?(String) }
    end
  end
end

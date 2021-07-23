# frozen_string_literal: true

require_relative 'setting'
require_relative 'exception'

module Config
  # Handles an entire group of settings
  class Group
    attr_reader :name, :parent

    def initialize(name, parent = nil)
      @name = name.to_s
      @parent = parent
      @entries = {}
    end

    def id
      @parent.nil? ? name.to_s : "#{@parent.id}.#{name}"
    end

    def subgroup?(name)
      @entries.key?(name) && @entries[name].is_a?(Group)
    end

    def setting?(name)
      @entries.key?(name) && @entries[name].is_a?(Setting)
    end

    def get(name)
      if subgroup?(name)
        @entries[name]
      elsif setting?(name)
        @entries[name].value
      else
        raise GroupException.new(self), "Unknown entry #{id}.#{name}."
      end
    end

    def set(name, value)
      if subgroup?(name)
        @entries[name].copy_from_hash(value)
      elsif setting?(name)
        @entries[name].value = value
      else
        raise GroupException.new(self), "Unknown entry #{id}.#{name}."
      end
    end

    def copy_from_hash(hash)
      raise GroupException.new(self), 'Expected to receive a hash to copy from.' unless hash.is_a?(Hash)

      hash.each do |name, entry|
        if subgroup?(name) || setting?(name)
          set(name, entry)
        else
          puts "Warning: Ignoring unknown entry #{id}.#{name}."
        end
      end
    end

    def to_hash
      res = {}

      @entries.each do |name, entry|
        res[name] = entry.to_hash if subgroup?(name)
        res[name] = entry.value if setting?(name)
      end

      res
    end

    def group(name, &block)
      raise GroupException.new(self), "The group #{@entries[name].id} already exists." if subgroup?(name)
      raise GroupException.new(self), "The group #{@entries[name].id} conflicts with a setting." if setting?(name)

      @entries[name] = Group.new(name, self)
      @entries[name].instance_eval(&block)

      register_methods(name)
    end

    def setting(name, default, &block)
      raise GroupException.new(self), "The setting #{@entries[name].id} conflicts with a group." if subgroup?(name)
      raise GroupException.new(self), "The setting #{@entries[name].id} already exists." if setting?(name)

      @entries[name] = Setting.new(self, name, default, &block)

      register_methods(name)
    end

    def register_methods(name)
      define_singleton_method name do
        get(name)
      end

      define_singleton_method "#{name}=".to_sym do |value|
        set(name, value)
      end
    end
  end
end

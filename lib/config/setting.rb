# frozen_string_literal: true

require_relative '../rftps'

module Config
  # Handles a specific config setting
  class Setting
    attr_reader :group, :name, :default_value, :value

    def initialize(group, name, default, &block)
      @group = group
      @name = name
      @default_value = default
      @value = default
      @block = block
    end

    def id
      "#{@group.id}.#{@name}"
    end

    def type
      @default_value.class
    end

    def value=(value)
      if @block.call(value)
        @value = value
      else
        Logging.warning "Invalid value (#{value}) for setting #{id}. Reverting to default value (#{@default_value})."
      end
    end

    def defaults
      @value = @default_value
    end
  end
end

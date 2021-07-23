# frozen_string_literal: true

module Config
  # Exception class for config module
  class GroupException < StandardError
    attr_reader :group

    def initialize(group)
      super
      @group = group
    end
  end
end

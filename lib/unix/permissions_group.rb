# frozen_string_literal: true

require_relative '../utils'

module Unix
  # Structure for permissions for one group
  class PermissionsGroup
    attr_accessor :read, :write, :execute

    def initialize(*args)
      case args&.length
      when 1 then initialize_single_arg(args[0].to_i)
      when 3 then initialize_three_args(args[0], args[1], args[2])
      else raise StandardError, 'Expected either 1 or 3 arguments.'
      end
    end

    def to_i
      oct = 0
      oct += 1 if @execute
      oct += 2 if @write
      oct += 4 if @read
      oct
    end

    def to_s
      [(@read ? 'r' : '-'), (@write ? 'w' : '-'), (@execute ? 'x' : '-')].join
    end

    private

    def initialize_single_arg(oct)
      raise StandardError, "Invalid octal number '#{oct}'." if oct.negative? || oct > 7

      @read = [4, 5, 6, 7].include? oct
      @write = [2, 3, 6, 7].include? oct
      @execute = [1, 3, 5, 7].include? oct
    end

    def initialize_three_args(read, write, execute)
      @read = Utils.to_boolean read
      @write = Utils.to_boolean write
      @execute = Utils.to_boolean execute
    end
  end
end

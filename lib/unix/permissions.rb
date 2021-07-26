# frozen_string_literal: true

require_relative '../unix'
require_relative 'permissions_group'

module Unix
  # File/directory permissions
  class Permissions
    attr_reader :owner, :group, :others

    def initialize(*args)
      case args.length
      when 1 then handle_single_argument(args[0])
      when 3
        @owner = PermissionsGroup.new(args[0])
        @group = PermissionsGroup.new(args[1])
        @others = PermissionsGroup.new(args[2])
      else raise StandardError, 'Expected 1 or 3 arguments.'
      end
    end

    def to_i
      @owner.to_i * 64 + @group.to_i * 8 + @others.to_i
    end

    def to_s
      [@owner, @group, @others].join
    end

    private

    def file_lookup(stat)
      stat.mode.to_s(8)[-4..].to_i(8)
    end

    def handle_single_argument(oct)
      oct = (oct.mode & 0o777) if oct.is_a?(File::Stat)
      oct = oct.to_i(8) if oct.is_a?(String)
      raise StandardError, "Invalid octal '#{oct}'." if !oct.is_a?(Integer) || oct.negative? || oct > 0o777

      oct = oct.to_s(8)

      @owner = PermissionsGroup.new(oct[0].to_i)
      @group = PermissionsGroup.new(oct[1].to_i)
      @others = PermissionsGroup.new(oct[2].to_i)
    end
  end
end

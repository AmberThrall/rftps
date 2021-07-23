# frozen_string_literal: true

module Unix
  # Unix group
  class Group
    attr_reader :id, :name

    def initialize(struct)
      @id = struct.gid
      @name = struct.name
    end

    def ==(other)
      other.is_a?(Unix::Group) && other.id == @id
    end

    def to_s
      @name
    end
  end
end

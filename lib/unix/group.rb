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
      case other.class
      when Unix::Group then other.id == @id
      when Integer then other == @id
      when String then other == @name
      else false
      end
    end

    def to_s
      @name
    end
  end
end

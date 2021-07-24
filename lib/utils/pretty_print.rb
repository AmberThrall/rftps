# frozen_string_literal: true

# Various utility methods
module Utils
  # Pretty printer
  class PrettyString
    def pretty_string(obj, indent_size = 2, indent = 0)
      case obj
      when Hash then pretty_string_hash(obj, indent_size, indent)
      when Array then pretty_string_array(obj, indent_size, indent)
      when String then "\"#{obj}\""
      else obj.to_s
      end
    end

    private

    def pretty_string_hash(hash, indent_size, indent)
      s = "{\n"
      hash.each_with_index do |(key, value), index|
        s += "#{' ' * indent} #{key}: #{pretty_string(value, indent_size, indent + indent_size)}"
        s += index < hash.size - 1 ? ",\n" : "\n"
      end
      "#{s}#{' ' * [0, indent - 1].max}}"
    end

    def pretty_string_array(array, indent_size, indent)
      s = '[ '
      array.each_with_index do |value, index|
        s += pretty_string(value, indent_size, indent + indent_size)
        s += index < array.size - 1 ? ', ' : ' '
      end
      "#{s}]"
    end
  end

  def self.pretty_string(obj, indent_size = 2, indent = 0)
    PrettyString.new.pretty_string(obj, indent_size, indent)
  end

  def self.pretty_print(obj, indent_size = 2)
    puts pretty_string(obj, indent_size)
  end
end

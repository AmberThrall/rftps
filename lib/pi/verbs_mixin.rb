# frozen_string_literal: true

require_relative 'verb'

module PI
  # Allows class level construction for verb handling
  module VerbsMixin
    class << self
      def included(base)
        base.extend ClassMethods
      end
    end

    # Actual implementations.
    module ClassMethods
      def verbs
        @verbs
      end

      def verb(name, opts = {}, &block)
        @verbs ||= {}
        name = name.to_s.upcase
        raise "Verb #{name} already defined." if @verbs.key?(name)

        @verbs[name] = Verb.new(name, "verb_#{name}".to_sym, opts)
        send(:define_method, "verb_#{name}".to_sym, &block)
      end
    end
  end
end

# frozen_string_literal: true

module PI
  # Class for VERB information and parsing
  class Verb
    attr_reader :name, :auth_only, :min_args, :max_args, :arg_sep, :split_args

    def initialize(name, method, opts = {})
      @name = name
      @auth_only = opts.key?(:auth_only) ? opts[:auth_only] : false
      @min_args = opts.key?(:min_args) ? opts[:min_args].to_i : 0
      @max_args = opts.key?(:max_args) ? opts[:max_args].to_i : -1
      @arg_sep = opts.key?(:arg_sep) ? opts[:arg_sep].to_s : ' '
      @split_args = opts.key?(:split_args) ? opts[:split_args] : true
      @method = method
    end

    def handle(client, args)
      args = split_args_string(args.to_s)
      if args.length < @min_args || (args.length > @max_args && @max_args >= 0)
        wrong_number_of_args client
      else
        call_method client, args
      end
    end

    private

    def call_method(client, args)
      case @max_args
      when 0 then client.send(@method)
      when 1 then client.send(@method, args.empty? ? nil : args[0])
      when @min_args then client.send(@method, *args)
      else client.send(@method, args)
      end
    end

    def split_args_string(args)
      return [] if args.empty?
      return Array(args) unless @split_args

      args = args.squeeze(' ') if @arg_sep == ' '
      args.split(@arg_sep)
    end

    def wrong_number_of_args(client)
      s = case @max_args
          when ..-1 then "Syntax error! Expected #{@min_args} or more arguments."
          when @min_args then "Syntax error! Expected #{@min_args} argument#{@min_args == 1 ? '' : 's'}."
          else "Syntax error! Expected #{@min_args}-#{@max_args} arguments."
          end

      client.message ResponseCodes::PARAMETER_SYNTAX_ERROR, s
    end
  end
end

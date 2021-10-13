# frozen_string_literal: true

require_relative 'result_wrapper'

module I2w
  module Repo
    # Proxy that wraps repo calls in a result_wrapper
    #
    # standard use
    #   UserRepo.new.create input: user_input
    #   # => ActiveRecord::NullViolation
    #   # => User(....)
    #
    # with ResultProxy
    #   ResultProxy.new(UserRepo).create input: user_input
    #   # => Result::Failure(user_input with errors)
    #   # => Result::Success(User(...))
    class ResultProxy
      def initialize(repository_class, input_class)
        @repository     = repository_class
        @result_wrapper = repository_class.result_wrapper
        @input_class    = input_class
      end

      def method_missing(method, ...)
        result = @result_wrapper.call { @repository.send(method, ...) }
        return result if result.success?

        convert_failure_to_input_failure(result, ...)
      end

      def respond_to_missing?(...) = @repository.respond_to?(...)

      def convert_failure_to_input_failure(result, *_args, **kwargs)
        input = kwargs[:input] || {}
        input = input.respond_to?(:valid?) ? input : new_input(input)
        input.errors = result.errors
        Result.failure input
      end

      def new_input(input)
        @input_class.new(input)
      rescue ArgumentError
        Input.new.with(input)
      end
    end
  end
end

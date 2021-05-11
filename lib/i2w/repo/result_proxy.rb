# frozen_string_literal: true

require_relative 'result_wrapper'

module I2w
  module Repo
    # Proxy that wraps repo calls in a result_wrapper
    #
    # standard use
    #   UserRepo.create user_input
    #   # => ActiveRecord::NullViolation
    #   # => User(....)
    #
    # with ResultProxy
    #   ResultProxy.new(UserRepo).create user_input
    #   # => Result::Failure(user_input with errors)
    #   # => Result::Success(User(...))
    class ResultProxy
      def initialize(repository_class, input_class = nil)
        @repository = repository_class.new
        @input_class = input_class || AssociatedClass.call(repository_class, :input)
      end

      def method_missing(method, ...)
        result = ResultWrapper.call { @repository.send(method, ...) }
        return result if result.success?

        convert_failure_to_input_failure(result, ...)
      end

      def respond_to_missing?(...)
        @repository.respond_to_missing?(...)
      end

      def convert_failure_to_input_failure(result, *_args, **kwargs)
        input = kwargs[:input] || {}
        input = input.respond_to?(:to_input) ? input.to_input : @input_class.new(input)
        input.errors = result.errors
        Result.failure(input)
      end
    end
  end
end

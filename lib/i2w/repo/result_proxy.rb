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
        @result_wrapper = repository_class::ResultWrapper
        @input_class    = input_class
      end

      def method_missing(...)
        result = repository_result(...)
        result.success? ? result : convert_failure_to_input_failure(result, ...)
      end

      def respond_to_missing?(...) = @repository.respond_to?(...)

      private

      def repository_result(method, ...)
        @result_wrapper.call { @repository.public_send(method, ...) }
      end

      def convert_failure_to_input_failure(result, *_args, **kwargs)
        input = kwargs[:input] || kwargs[:by] || {}
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

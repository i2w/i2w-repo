# frozen_string_literal: true

require_relative 'result_wrapper'

module I2w
  module Repo
    # Proxy that wraps repo calls in a result_wrapper
    #
    # standard use
    #   UserRepo.new.create user_input
    #   # => ActiveRecord::NullViolation
    #   # => User(....)
    #
    # with ResultProxy
    #   ResultProxy.new(UserRepo).create user_input
    #   # => Result::Failure(user_input with errors)
    #   # => Result::Success(User(...))
    class ResultProxy
      def initialize(repository_class, input_class)
        @repository = repository_class
        @input_class = input_class
      end

      def method_missing(method, ...)
        result = ResultWrapper.call { @repository.send(method, ...) }
        return result if result.success?

        convert_failure_to_input_failure(result, ...)
      end

      def respond_to_missing?(...) = @repository.respond_to?(...)

      def convert_failure_to_input_failure(result, *_args, **kwargs)
        input = input_with_result_errors(result, kwargs)
        model = attempt_load_model(kwargs) if kwargs[:id] && result.failure != :not_found
        input = Input::WithModel.new(input, model) if model
        Result.failure(input)
      end

      def input_with_result_errors(result, kwargs)
        input = kwargs[:input] || {}
        input = begin
          input.respond_to?(:to_input) ? input.to_input : @input_class.new(input)
        rescue ArgumentError
          Input.new
        end
        input.errors = result.errors
        input
      end

      def attempt_load_model(kwargs)
        id = kwargs.fetch(:id)
        to_model = kwargs.fetch(:to_model, {})
        @repository.find(id: id, **to_model)
      rescue ActiveRecord::ActiveRecordError
        nil
      end
    end
  end
end

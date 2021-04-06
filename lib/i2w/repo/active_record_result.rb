# frozen_string_literal: true

module I2w
  module Repo
    # Utility to wrap an active record operation in a result.
    # It converts some active record errors into failures with useful errors
    module ActiveRecordResult
      extend self

      # yields the block and returns the result in Result.success monad
      # Rescues a variety of active record errors and returns appropriate Result.failure monads
      def call
        Result.success yield
      rescue ActiveRecord::RecordNotFound => e
        not_found_failure(e)
      rescue ActiveRecord::NotNullViolation => e
        presence_failure(e)
      rescue ActiveRecord::RecordNotUnique => e
        uniqueness_failure(e)
      end

      private

      def not_found_failure(exception)
        Result.failure :not_found, id: [exception.message]
      end

      def presence_failure(exception)
        attribute = (exception.message[/\w+\.(\w+)/, 1] || :unknown).to_sym

        Result.failure :db_constraint, attribute => ["can't be blank"]
      end

      def uniqueness_failure(exception)
        attributes = exception.message.scan(/\w+\.(\w+)/).flatten
        *scope, attribute = attributes
        message = 'is taken'
        message = "#{message} in scope #{scope.join(', ')}"

        Result.failure :db_constraint, attribute => [message]
      end
    end
  end
end

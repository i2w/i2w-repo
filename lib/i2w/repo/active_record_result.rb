# frozen_string_literal: true

require 'active_model/errors'

module I2w
  class Repo
    # Utility to wrap an active record operation in a result.
    # It converts some active record errors into failures with useful errors
    class ActiveRecordResult
      def initialize(errors_base = Input.new)
        @errors_base = errors_base
      end

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
        Result.failure :not_found, error(:id, :not_found)
      end

      def presence_failure(exception)
        # currently only works in postgres
        attribute = exception.message[/column "(\w+)"/, 1] || 'unknown'
        Result.failure :db_constraint, error(attribute, :blank)
      end

      def uniqueness_failure(exception)
        # currently only works for postgres
        attribute = exception.message[/Key .*?(\w+)\)?=/, 1] || 'unknown'
        Result.failure :db_constraint, error(attribute, :taken)
      end

      def error(attribute, error)
        @errors_base.errors.add(attribute, error)
        @errors_base.errors
      end
    end
  end
end

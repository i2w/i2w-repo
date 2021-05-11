# frozen_string_literal: true

require 'active_model/errors'
require 'i2w/result'

module I2w
  module Repo
    # Utility to wrap an active record operation in a result.
    # It converts some active record errors into failures with useful errors
    module ResultWrapper
      extend self

      # yields the block and returns the result in Result.success monad
      # Rescues a variety of active record errors and returns an appropriate Result.failure monad
      def call
        Result.success(yield)
      rescue ActiveRecord::RecordNotFound => e
        not_found_failure(e)
      rescue ActiveRecord::NotNullViolation => e
        presence_failure(e)
      rescue ActiveRecord::RecordNotUnique => e
        uniqueness_failure(e)
      end

      private

      def not_found_failure(_exception)
        failure(:not_found, :id, :not_found)
      end

      def presence_failure(exception)
        # currently only works in postgres
        attribute = exception.message[/column "(\w+)"/, 1] || 'unknown'
        failure(:db_constraint, attribute, :blank)
      end

      def uniqueness_failure(exception)
        # currently only works for postgres
        attribute = exception.message[/Key .*?(\w+)\)?=/, 1] || 'unknown'
        failure(:db_constraint, attribute, :taken)
      end

      def failure(failure, attribute, error)
        errors = ActiveModel::Errors.new(nil).tap { _1.add(attribute, error) }
        Result.failure(failure, errors)
      end
    end
  end
end

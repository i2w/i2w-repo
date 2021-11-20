# frozen_string_literal: true

require 'active_model/errors'
require 'i2w/result'

module I2w
  module Repo
    # Utility to wrap an active record operation in a result.
    # It converts some active record errors into failures with useful errors
    class ResultWrapper
      class << self
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

        def not_found_failure(exception)
          Result.failure exception, exception.message
        end

        def presence_failure(exception)
          # currently only works in postgres
          attribute = exception.message[/column "(\w+)"/, 1]
          Result.failure exception, attribute ? { attribute => :blank } : exception.message
        end

        def uniqueness_failure(exception)
          # currently only works for postgres
          attribute = exception.message[/Key .*?(\w+)\)?=/, 1]
          Result.failure exception, attribute ? { attribute => :taken } : exception.message
        end
      end
    end
  end
end

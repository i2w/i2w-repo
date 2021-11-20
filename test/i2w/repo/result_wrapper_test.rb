# frozen_string_literal: true

require 'test_helper'

module I2w
  module Repo
    class ResultWrapperTest < ActiveSupport::TestCase
      test 'adds base error for ActiveRecord::RecordNotFound' do
        actual = ResultWrapper.call { raise ActiveRecord::RecordNotFound, 'could not find it' }
        assert actual.failure?
        assert actual.failure.is_a?(ActiveRecord::RecordNotFound)
        assert_equal({ base: [{ error: 'could not find it' }] }, actual.errors.details)
      end

      test 'adds error for column for ActiveRecord::NotNullViolation with postgres message' do
        actual = ResultWrapper.call do
          raise ActiveRecord::NotNullViolation, 'null value in column "foo" of relation "bar" violates'
        end
        assert actual.failure?
        assert actual.failure.is_a?(ActiveRecord::NotNullViolation)
        assert_equal({ foo: [{ error: :blank }] }, actual.errors.details)
      end

      test 'adds base error for ActiveRecord::NotNullViolation with non postgres message' do
        actual = ResultWrapper.call do
          raise ActiveRecord::NotNullViolation, 'oops "foo"'
        end
        assert actual.failure?
        assert actual.failure.is_a?(ActiveRecord::NotNullViolation)
        assert_equal({ base: [{ error: 'oops "foo"' }] }, actual.errors.details)
      end

      test 'adds error for column for ActiveRecord::RecordNotUnique with postgres message' do
        actual = ResultWrapper.call do
          raise ActiveRecord::RecordNotUnique, 'Key (foo)=(bar) already exists'
        end
        assert actual.failure?
        assert actual.failure.is_a?(ActiveRecord::RecordNotUnique)
        assert_equal({ foo: [{ error: :taken }] }, actual.errors.details)
      end

      test 'adds base error for ActiveRecord::RecordNotUnique with non postgres message' do
        actual = ResultWrapper.call do
          raise ActiveRecord::RecordNotUnique, 'oops "foo"'
        end
        assert actual.failure?
        assert actual.failure.is_a?(ActiveRecord::RecordNotUnique)
        assert_equal({ base: [{ error: 'oops "foo"' }] }, actual.errors.details)
      end
    end
  end
end
# frozen_string_literal: true

require 'test_helper'

module I2w
  class Repo
    class ExceptionsTest < ActiveSupport::TestCase
      class UnhandledError < RuntimeError; end

      class OtherError < RuntimeError; end

      class TestRepo < Repo
        def unhandled
          model_result { raise UnhandledError, 'is not handled' }
        end

        def not_found(input = nil)
          model_result(input: input) { raise ActiveRecord::RecordNotFound, 'could not find it' }
        end

        def not_null_postgres(input = nil)
          model_result(input: input) { raise ActiveRecord::NotNullViolation, 'null value in column "foo" of relation "bar" violates' }
        end

        def not_null_other(input = nil)
          model_result(input: input) { raise ActiveRecord::NotNullViolation, 'oops "foo"' }
        end

        def not_unique_postgres(input = nil)
          model_result(input: input) { raise ActiveRecord::RecordNotUnique, 'Key (foo)=(bar) already exists' }
        end

        def not_unique_other(input = nil)
          model_result(input: input) { raise ActiveRecord::RecordNotUnique, 'oops "foo"' }
        end
      end

      class TestInput < Input
        attribute :foo
      end

      class Test2Repo < TestRepo
        exception UnhandledError, -> { _1.message }
        exception OtherError, -> { { msg: 'other' } }

        def other
          model_result { raise OtherError }
        end
      end

      test 'unhandled error is raised' do
        assert_raises UnhandledError do
          TestRepo.unhandled
        end
      end

      test 'adds base error for ActiveRecord::RecordNotFound' do
        actual = TestRepo.not_found
        assert actual.failure?
        assert actual.failure.is_a?(ActiveRecord::RecordNotFound)
        assert_equal({ base: [{ error: 'could not find it' }] }, actual.errors.details)
      end

      test 'adds error to input for ActiveRecord::RecordNotFound if passed' do
        input = TestInput.new
        actual = TestRepo.not_found(input)
        assert actual.failure?
        assert actual.failure.is_a?(TestInput)
        assert_equal({ base: [{ error: 'could not find it' }] }, actual.errors.details)
      end

      test 'adds error for column for ActiveRecord::NotNullViolation with postgres message' do
        actual = TestRepo.not_null_postgres
        assert actual.failure?
        assert actual.failure.is_a?(ActiveRecord::NotNullViolation)
        assert_equal({ foo: [{ error: :blank }] }, actual.errors.details)
      end

      test 'adds error to input for column for ActiveRecord::NotNullViolation with postgres message' do
        input = TestInput.new
        actual = TestRepo.not_null_postgres(input)
        assert actual.failure?
        assert actual.failure.is_a?(TestInput)
        assert_equal ["can't be blank"], actual.failure.errors[:foo]
      end

      test 'adds base error for ActiveRecord::NotNullViolation with non postgres message' do
        actual = TestRepo.not_null_other
        assert actual.failure?
        assert actual.failure.is_a?(ActiveRecord::NotNullViolation)
        assert_equal({ base: [{ error: 'oops "foo"' }] }, actual.errors.details)
      end

      test 'adds error for column for ActiveRecord::RecordNotUnique with postgres message' do
        input = TestInput.new
        actual = TestRepo.not_unique_postgres(input)
        assert actual.failure?
        assert actual.failure.is_a?(TestInput)
        assert_equal ["has already been taken"], actual.failure.errors[:foo]
      end

      test 'adds base error for ActiveRecord::RecordNotUnique with non postgres message' do
        actual = TestRepo.not_unique_other
        assert actual.failure?
        assert actual.failure.is_a?(ActiveRecord::RecordNotUnique)
        assert_equal({ base: [{ error: 'oops "foo"' }] }, actual.errors.details)
      end

      test 'subclass with handler' do
        actual = Test2Repo.unhandled
        assert actual.failure?
        assert actual.failure.is_a?(UnhandledError)
      end

      test 'handler can have 0 arity' do
        actual = Test2Repo.other
        assert actual.failure?
        assert actual.failure.is_a?(OtherError)
        assert_equal({ msg: [{ error: "other" }]}, actual.errors.details)
      end
    end
  end
end
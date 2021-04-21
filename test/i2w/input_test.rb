# frozen_string_literal: true

require 'test_helper'

module I2w
  class InputTest < ActiveSupport::TestCase
    class FooInput < Input
      attribute :foo

      validates :foo, presence: true, format: { with: /bar/, allow_blank: true }
    end

    test 'valid input' do
      input = FooInput.new(foo: 'bar bar black sheep')

      assert input.valid?
      assert_equal({ foo: 'bar bar black sheep' }, input.attributes)
      assert_equal({ foo: 'bar bar black sheep' }, { **input })
    end

    test 'invalid input' do
      input = FooInput.new(foo: 'baa baa black sheep')

      refute input.valid?
      assert_raises(Input::InvalidAttributesError) { input.attributes }
      assert_raises(Input::InvalidAttributesError) { { **input } }
    end

    test 'unknown, empty or partial input via #new creates an Input' do
      input = FooInput.new(xxx: 'xxx')
      refute input.valid?
    end

    test '#errors= replaces errors' do
      other = FooInput.new
      refute other.valid?
      assert_equal({ foo: [{ error: :blank }] }, other.errors.details)

      input = FooInput.new(foo: 'xxx')
      refute input.valid?
      assert_equal({ foo: [{ error: :invalid, value: 'xxx' }] }, input.errors.details)

      input.errors = other.errors
      assert_equal({ foo: [{ error: :blank }] }, input.errors.details)
    end
  end
end

# frozen_string_literal: true

require 'test_helper'

module I2w
  class InputTest < ActiveSupport::TestCase
    class Foo < Model
      attribute :foo
    end

    class FooInput < Input
      attribute :foo
      attribute :faz

      validates :foo, presence: true, format: { with: /bar/, allow_blank: true }
    end

    test 'valid input' do
      input = FooInput.new(foo: 'bar bar black sheep')

      assert input.valid?
      assert_equal({ foo: 'bar bar black sheep', faz: nil }, input.attributes)
      assert_equal({ foo: 'bar bar black sheep', faz: nil }, input.attributes_hash)
      assert_equal({ foo: 'bar bar black sheep', faz: nil }, { **input })
    end

    test 'invalid input' do
      input = FooInput.new(foo: 'baa baa black sheep')

      refute input.valid?
      assert_raises(Input::InvalidAttributesError) { input.attributes }
      assert_raises(Input::InvalidAttributesError) { { **input } }
      assert_raises(Input::InvalidAttributesError) { input[:foo] }
      assert_equal({ foo: 'baa baa black sheep', faz: nil }, input.attributes_hash)
      assert_equal('baa baa black sheep', input.attributes_hash[:foo])
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

    test '#errors with i18n' do
      actual = FooInput.new foo: "FOO"
      actual.errors.add(:foo, :too_short, count: 5)
      actual.errors.add(:faz, :blank)
      actual.errors.add(:zoo, :taken)

      assert_equal ["Foo is too short (minimum is 5 characters)", "Faz can't be blank", "Zoo has already been taken"],
                   actual.errors.full_messages
    end

    test 'how to patch an input' do
      existing = FooInput.new(foo: 'bar', faz: 'baz')

      patched_by_hash = FooInput.new(**existing, **{ 'faz' => 'BAZ' })
      patched_by_kwargs = FooInput.new(**existing, faz: 'BAZ')

      assert_equal({ foo: 'bar', faz: 'BAZ' }, patched_by_hash.attributes)
      assert_equal({ foo: 'bar', faz: 'BAZ' }, patched_by_kwargs.attributes)
    end

    test '.with(attrs) adds arbitrary attributes to the input, useful for sending extra attrs to Repo methods' do
      input = FooInput.new(foo: 'bar', faz: 'faz')
      actual = input.with(bar: 'foo', faz: 'OVERIDDEN')

      assert_equal({ foo: 'bar', faz: 'OVERIDDEN', bar: 'foo'}, { **actual })
      assert_equal 'Foo input', actual.model_name.human

      model = Foo.new(foo: 'OVERRIDDEN')
      actual = input.with(model)
      assert_equal({ foo: 'OVERRIDDEN', faz: 'faz' }, actual.attributes_hash)
      assert_equal({ foo: 'OVERRIDDEN', faz: 'faz' }, { **actual })
    end

    test '.with(attrs).with(other) works as expected' do
      input = FooInput.new(foo: 'bar', faz: 'faz')
      actual = input.with(bar: 'bar').with(foo: 'OVERRIDDEN').with(bang: 'bang')

      assert_equal({ foo: 'OVERRIDDEN', faz: 'faz', bar: 'bar', bang: 'bang' }, { **actual })
    end

    test '.with(attrs).class returns the original class' do
      actual = FooInput.new(foo: 'bar', faz: 'faz').with(bar: 'bar')

      assert_equal FooInput, actual.class
      assert_equal Input::WithAttributes, actual.delegator_class
    end
  end
end

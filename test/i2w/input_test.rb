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
      assert_equal({ foo: 'bar bar black sheep', faz: nil }, { **input })
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

    test 'how to patch an input' do
      existing = FooInput.new(foo: 'bar', faz: 'baz')

      patched_by_hash = FooInput.new(**existing, **{ 'faz' => 'BAZ' })
      patched_by_kwargs = FooInput.new(**existing, faz: 'BAZ')

      assert_equal({ foo: 'bar', faz: 'BAZ' }, patched_by_hash.attributes)
      assert_equal({ foo: 'bar', faz: 'BAZ' }, patched_by_kwargs.attributes)
    end

    test 'model_class' do
      assert_equal Foo, Repo.lookup(FooInput, :model)
    end

    test '.with_model(model)' do
      model = Foo.new(foo: 'bar')
      input_with_model = FooInput.with_model(model)

      assert_equal model, input_with_model.model
      assert_equal 'bar', input_with_model.input.foo
    end
  end
end

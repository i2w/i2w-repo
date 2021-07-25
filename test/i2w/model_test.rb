# frozen_string_literal: true

require 'test_helper'

module I2w
  class ModelTest < ActiveSupport::TestCase
    class PersistedFoo < Model::Persisted
      attribute :name
    end

    class Bar < Model
      attribute :name
    end

    test 'raises an error if persisted model instantiated missing id, timestamps, and attributes' do
      error = assert_raises(DataObject::MissingAttributeError) { PersistedFoo.new }
      assert_equal 'Missing attribute [:id, :updated_at, :created_at, :name]', error.message
    end

    test 'raises an error if model instantiated missing attributes' do
      error = assert_raises(DataObject::MissingAttributeError) { Bar.new }
      assert_equal 'Missing attribute [:name]', error.message
    end

    test 'ActiveModel::Conversion for persisted model' do
      foo = PersistedFoo.from(id: 1)

      assert_equal '1', foo.to_param
      assert_equal [1], foo.to_key
      assert_equal 'i2w/model_test/persisted_foos/persisted_foo', foo.to_partial_path
      assert_equal foo, foo.to_model
    end

    test 'ActiveModel::Naming' do
      assert_equal 'Bar', Bar.model_name.human
      assert_equal 'Persisted foo', PersistedFoo.model_name.human
    end

    test 'equality for persisted model depends on id' do
      assert_equal PersistedFoo.from(id: 1), PersistedFoo.from(id: 1)
      assert_not_equal PersistedFoo.from(id: 1), PersistedFoo.from(id: 2)
    end

    test 'equality for non persisted model depends on attributes' do
      assert_equal Bar.new(name: 'foo'), Bar.new(name: 'foo')
      assert_not_equal Bar.new(name: 'foo'), Bar.new(name: 'bar')
    end
  end
end

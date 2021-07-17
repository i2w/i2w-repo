# frozen_string_literal: true

require 'test_helper'

module I2w
  class RecordTest < ActiveSupport::TestCase
    class Foo; end

    class FooRecord < Record
      has_many :bars
      has_one :baz
    end

    class Abstract < Record
      self.abstract_class = true
    end

    class BarRecord < Abstract
      belongs_to :foo
    end

    class BazRecord < Record
      belongs_to :foo

      self.table_name = 'bazzes'

      self.group_name = Foo
    end

    test 'table_name defaults to standard active record table name, but can be overridden' do
      assert_equal 'foos', FooRecord.table_name
      assert_equal 'bars', BarRecord.table_name
      assert_equal 'bazzes', BazRecord.table_name
    end

    test 'associated classes' do
      assert_equal Foo, Repo.lookup(FooRecord, :model)
      assert_equal Foo, Repo.lookup(BazRecord, :model)
      assert_equal FooRecord, Repo.lookup('I2w::RecordTest::Foo', :record)
    end

    test 'has_many' do
      reflection = FooRecord.reflect_on_association(:bars)
      assert_equal ActiveRecord::Reflection::HasManyReflection, reflection.class
      assert_equal 'BarRecord', reflection.class_name
      assert_equal 'foo_id', reflection.foreign_key
    end

    test 'has_one' do
      reflection = FooRecord.reflect_on_association(:baz)
      assert_equal ActiveRecord::Reflection::HasOneReflection, reflection.class
      assert_equal 'BazRecord', reflection.class_name
      assert_equal 'foo_id', reflection.foreign_key
    end

    test 'belongs_to' do
      reflection = BarRecord.reflect_on_association(:foo)
      assert_equal ActiveRecord::Reflection::BelongsToReflection, reflection.class
      assert_equal 'FooRecord', reflection.class_name
      assert_equal 'foo_id', reflection.foreign_key
    end
  end
end

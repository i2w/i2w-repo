# frozen_string_literal: true

require 'test_helper'

module I2w
  class RecordTest < ActiveSupport::TestCase
    class Foo; end

    class FooRecord < Record
    end

    class Abstract < Record
      self.abstract_class = true
    end

    class BarRecord < Abstract
    end

    class BazRecord < Record
      self.table_name = 'bazzes'
      self.model_class = Foo
    end

    test 'table_name defaults to standard active record table name, but can be overridden' do
      assert_equal 'foos', FooRecord.table_name
      assert_equal 'bars', BarRecord.table_name
      assert_equal 'bazzes', BazRecord.table_name
    end

    test 'associated classes' do
      assert_equal Foo, FooRecord.model_class
      assert_equal Foo, BazRecord.model_class
    end
  end
end

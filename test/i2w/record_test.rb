# frozen_string_literal: true

require 'test_helper'

module I2w
  class RecordTest < ActiveSupport::TestCase
    class FooRecord < Record
    end

    class BarRecord < Record
      self.table_name = 'bar_bars'
    end

    test 'table_name defaults to standard active record table name, but can be overridden' do
      assert_equal 'foos', FooRecord.table_name
      assert_equal 'bar_bars', BarRecord.table_name
    end
  end
end

# frozen_string_literal: true

require 'active_record'

module I2w
  # record base class
  class Record < ActiveRecord::Base
    self.abstract_class = true

    # apply any concerns
    def self.inherited(subclass)
      super
      subclass.extend TableName
    end

    # table name extension
    module TableName
      # remove '_records' suffix from computed table_name
      def table_name
        unless defined?(@table_name)
          super
          @table_name = @table_name.sub(/_records\z/, '').pluralize if @table_name.match?(/_records\z/)
        end
        @table_name
      end
    end
  end
end

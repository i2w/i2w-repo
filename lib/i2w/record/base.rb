# frozen_string_literal: true

module I2w
  module Record
    # Base class for records
    class Base < ActiveRecord::Base
      self.abstract_class = true

      # apply any concerns
      def self.inherited(subclass)
        super
        subclass.include Concerns::TableName
      end
    end
  end
end

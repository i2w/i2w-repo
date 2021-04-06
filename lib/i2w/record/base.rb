# frozen_string_literal: true

module I2w
  module Record
    # Base class for records
    class Base < ActiveRecord::Base
      self.abstract_class = true

      # apply any mixins/extensions
      def self.inherited(subclass)
        super
        subclass.extend Record::DefaultTableNameExtension
      end
    end
  end
end

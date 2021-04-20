# frozen_string_literal: true

require 'active_record'

module I2w
  # record base class
  class Record < ActiveRecord::Base
    self.abstract_class = true

    class << self
      private

      # remove '_records' suffix from computed table_name
      def compute_table_name
        computed = super
        computed = computed.sub(/_records\z/, '').pluralize if computed.match?(/_records\z/)
        computed
      end
    end
  end
end

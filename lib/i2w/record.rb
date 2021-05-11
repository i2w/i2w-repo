# frozen_string_literal: true

require 'active_record'
require_relative 'repo/associated_class_accessor'

module I2w
  # record base class
  class Record < ActiveRecord::Base
    extend Repo::AssociatedClassAccessor
    
    associated_class_accessor model: -> { name.sub(/Record\z/, '').constantize }

    self.abstract_class = true

    def to_hash
      attributes.symbolize_keys
    end
    alias to_h to_hash

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

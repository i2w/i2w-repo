# frozen_string_literal: true

require 'active_record'

module I2w
  # record base class
  class Record < ActiveRecord::Base
    Repo.register_class self, :record

    self.abstract_class = true

    def to_hash
      attributes.symbolize_keys
    end
    alias to_h to_hash

    class << self
      def has_many(name, scope = nil, class_name: nil, foreign_key: nil, **options)
        class_name ||= "#{name.to_s.singularize.camelize}Record"
        foreign_key ||= model_name.to_s.foreign_key.sub(/_record_id\z/, '_id')
        super(name, scope, class_name: class_name, foreign_key: foreign_key, **options)
      end

      def has_one(name, scope = nil, class_name: nil, foreign_key: nil,  **options)
        class_name ||= "#{name.to_s.camelize}Record"
        foreign_key ||= model_name.to_s.foreign_key.sub(/_record_id\z/, '_id')
        super(name, scope, class_name: class_name, foreign_key: foreign_key, **options)
      end

      def belongs_to(name, scope = nil, class_name: nil, **options)
        class_name ||= "#{name.to_s.camelize}Record"
        super(name, scope, class_name: class_name, **options)
      end

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

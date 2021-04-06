# frozen_string_literal: true

module I2w
  module Repo 
    # Application repo base class
    class Base
      class << self
        def transaction(&block)
          ActiveRecord::Base.transaction(&block)
        end

        # TODO: Query objects
        def all
          record_class.all.map { |record| to_model(record.attributes) }
        end

        def create(input)
          active_record_result do
            record = record_class.create!(**input)
            to_model(record.attributes)
          end
        end

        def find(id)
          active_record_result do
            record = record_class.find(id)
            to_model(record.attributes)
          end
        end

        def update(id, input)
          active_record_result do
            record = record_class.find(id)
            record.update!(**input)
            to_model(record.attributes)
          end
        end

        def delete(id)
          active_record_result do
            record = record_class.find(id)
            record.destroy!
            to_model(record.attributes)
          end
        end

        attr_writer :model_class, :record_class

        def model_class
          @model_class ||= associated_class('') # model classes have no suffix
        end

        def record_class
          @record_class ||= associated_class('Record')
        end

        private

        def to_model(attributes)
          model_class.new(**attributes.symbolize_keys)
        end

        def active_record_result(...)
          ActiveRecordResult.call(...)
        end

        def associated_class(suffix)
          *nesting, name = self.name.split('::')
          name = name.sub(/Repo\z/, suffix)
          [*nesting, name].join('::').constantize
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'active_record'

require_relative 'input'
require_relative 'model'
require_relative 'record'

require_relative 'repo/version'
require_relative 'repo/active_record_result'

module I2w
  # Repo class. Subclass this to define a repository.
  class Repo
    class << self
      def transaction(&block)
        # we expect transactions to be nested, we pass `requires_new: true`
        # @see https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#module-ActiveRecord::Transactions::ClassMethods-label-Nested+transactions
        ActiveRecord::Base.transaction(requires_new: true, &block)
      end

      # TODO: Query objects, which are instances of a query monad (all read only)
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
          transaction do
            record = record_class.find(id)
            record.update!(**input)
          end
          to_model(record.attributes)
        end
      end

      def delete(id)
        active_record_result do
          transaction do
            record = record_class.find(id)
            record.destroy!
          end
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

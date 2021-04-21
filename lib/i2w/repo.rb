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
        # we expect transactions to be nested, so we set sane defaults for this
        # @see https://makandracards.com/makandra/42885-nested-activerecord-transaction-pitfalls
        ActiveRecord::Base.transaction(joinable: false, requires_new: true, &block)
      end

      def rollback!
        raise ActiveRecord::Rollback
      end

      # TODO: Query objects, which are instances of a query monad (all read only)
      def all
        record_class.all.map { |record| to_model record }
      end

      def create(input)
        active_record_result do
          to_model record_class.create!(**input)
        end
      end

      def find(id)
        active_record_result do
          to_model record_class.find(id)
        end
      end

      def update(id, input)
        active_record_result do
          record = transaction { record_class.find(id).update!(**input) }
          to_model record
        end
      end

      def delete(id)
        active_record_result do
          record = transaction { record_class.find(id).destroy! }
          to_model record
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

      def to_model(record)
        model_class.new(**record.attributes.symbolize_keys)
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

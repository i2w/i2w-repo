# frozen_string_literal: true

require 'active_record'

require_relative 'repo/version'
require_relative 'input'
require_relative 'model'
require_relative 'record'

module I2w
  # Repo class. Subclass this to define a repository.
  class Repo
    class << self
      attr_writer :model_class, :record_class

      def model_class = @model_class ||= associated_class('')

      def record_class = @record_class ||= associated_class('Record')

      def instance
        @instance ||= new
      end

      # delegate all publicly defined methods to our instance
      def method_added(method_name)
        super
        return unless public_method_defined?(method_name)

        singleton_class.delegate method_name, to: :instance
      end

      private

      def associated_class(suffix)
        *nesting, name = self.name.split('::')
        name = name.sub(/Repo\z/, suffix)
        [*nesting, name].join('::').constantize
      end
    end

    delegate :model_class, :record_class, to: 'self.class', private: true

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
      record_class.all.map { to_model _1 }
    end

    def create(input)
      to_model record_class.create!(**input)
    end

    def find(id)
      to_model record_class.find(id)
    end

    def update(id, input)
      record = record_class.find(id)
      record.update!(**input)

      to_model record
    end

    def destroy(id)
      record = record_class.find(id)
      record.destroy!

      to_model record
    end

    private

    def to_model(record)
      attributes_to_model(**record)
    end

    def attributes_to_model(**attributes)
      model_class.new(**attributes)
    end
  end
end

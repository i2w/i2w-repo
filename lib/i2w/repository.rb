# frozen_string_literal: true

require 'active_record'

require_relative 'model'
require_relative 'record'

module I2w
  # Repository class. Subclass this to define a repository.
  # A Repository class is not meant to be instantiated, and holds no application state
  # Repository methods return models, raise ActiveRecord errors, and are quite simple to write.
  # By convention they use named arguments id:, and input: for CRUD methods
  class Repository
    Repo.register_class self, :repository, accessors: %i[model record]

    ResultWrapper = Repo::ResultWrapper

    class << self
      def new = raise("#{name} is a singleton object, call methods on the class itself")

      def method_added(method) = raise("instance method :#{method} was added to #{name}, add singelton methods only")

      # TODO: Query objects, which are instances of a query monad (all read only)
      def all
        record_class.all.map { to_model _1 }
      end

      def create(input:)
        to_model record_class.create!(**input)
      end

      def find(id:)
        to_model record_class.find(id)
      end

      def update(id:, input:)
        record = transaction { record_class.find(id).tap { _1.update!(**input) } }
        to_model record
      end

      def destroy(id:)
        record = transaction { record_class.find(id).tap(&:destroy!) }
        to_model record
      end

      def to_model(record)
        attributes_to_model(**record)
      end

      def result_wrapper = self::ResultWrapper

      private

      def transaction(&block)
        # we expect transactions to be nested, so we set sane defaults for this
        # @see https://makandracards.com/makandra/42885-nested-activerecord-transaction-pitfalls
        ActiveRecord::Base.transaction(joinable: false, requires_new: true, &block)
      end

      def rollback!
        raise ActiveRecord::Rollback
      end

      def attributes_to_model(**attributes)
        model_class.new(**attributes)
      end
    end
  end
end
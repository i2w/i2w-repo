# frozen_string_literal: true

require 'active_record'

require_relative 'repo/class_accessor'
require_relative 'model'
require_relative 'record'

module I2w
  # Repository class. Subclass this to define a repository.
  # Repository methods return models, raise ActiveRecord errors, and are quite simple to write.
  # By convention they use named arguments id:, and input: for CRUD methods
  class Repository
    extend Repo::ClassAccessor

    repo_class_accessor :record, model: -> { name.sub(/Repository\z/, '').constantize }

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

    private

    delegate :record_class, :model_class, to: 'self.class', private: true

    def transaction(&block)
      # we expect transactions to be nested, so we set sane defaults for this
      # @see https://makandracards.com/makandra/42885-nested-activerecord-transaction-pitfalls
      ActiveRecord::Base.transaction(joinable: false, requires_new: true, &block)
    end

    def rollback!
      raise ActiveRecord::Rollback
    end

    def to_model(record)
      attributes_to_model(**record)
    end

    def attributes_to_model(**attributes)
      model_class.new(**attributes)
    end
  end
end

# frozen_string_literal: true

require 'active_record'
require 'i2w/result'

require_relative 'repo/version'
require_relative 'class_lookup'
require_relative 'dependencies'
require_relative 'input'
require_relative 'model'
require_relative 'list'
require_relative 'record'
require_relative 'repo/class_methods'
require_relative 'repo/instance_methods'

module I2w
  # Repository class. Subclass this to define a repository.  Send methods directly to the repository
  class Repo
    NoArg = I2w::NoArg
    Result = I2w::Result

    extend Dependencies
    extend ClassMethods
    include InstanceMethods

    dependency :list_class,   List,                                        public: true
    dependency :model_class,  class_lookup { _1.sub(/Repo\z/, '') },       public: true
    dependency :record_class, class_lookup { _1.sub(/Repo\z/, 'Record') }, public: true

    # find a model by id:, or by: <attrs>
    # returns Success(model), or Failure(error)
    def find(id: NoArg, by: NoArg)
      raise ArgumentError, 'pass id: or by:, not both' unless ([id, by] - [NoArg]).size == 1
      return model_result { scope.find(id) } unless id == NoArg

      model_result { scope.find_by!(**by) }
    end

    # create a record with the input: <attrs>
    # returns Success(model), Failure(input) if Input object given, or Failure(error)
    def create(input:)
      model_result(input) { record_class.create(**input) }
    end

    # update the record with id: with input: <attrs>
    # returns Success(model), Failure(input) if Input object given, or Failure(error)
    def update(id:, input:)
      model_result input, transaction: true do
        scope.find(id).tap do |record|
          record.update!(**input)
        end
      end
    end

    # find or initialize record by: <attrs>, updating with input: <attrs>
    # returns Success(model), Failure(input) if Input object given, or Failure(error)
    def upsert(by:, input: nil)
      model_result input, transaction: true do
        record_class.find_or_initialize_by(**by).tap do |record|
          record.update!(**input) if input
        end
      end
    end

    # destory the record found by id:
    # returns Success(model), or Failure(error)
    def destroy(id:)
      model_result transaction: true do
        scope.find(id).tap(&:destroy!)
      end
    end

    # returns List(models)
    def all = list(scope.all)

    # this is done automatically for methods defined on your own repos, but its more performant to set this up
    # here for the abstract repo
    class << self
      delegate :find, :create, :update, :upsert, :destroy, :all, to: :instance
    end

    # Return failure with the exception message for ActiveRecord errors
    exception ActiveRecord::ActiveRecordError, -> { _1.message }

    # handle postgres RecordNotUnique as :taken error
    exception ActiveRecord::RecordNotUnique do |exception|
      if attribute = exception.message[/Key .*?(\w+)\)?=/, 1]
        { attribute => :taken }
      end
    end

    # handle postgres null violation as :blank error
    exception ActiveRecord::NotNullViolation do |exception|
      if attribute = exception.message[/column "(\w+)"/, 1]
        { attribute => :blank }
      end
    end
  end
end
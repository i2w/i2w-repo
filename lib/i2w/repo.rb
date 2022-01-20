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

    # find a model by pkey, or by: <attrs>
    # returns Success(model), or Failure(error)
    def find(pkey = NoArg, by: NoArg)
      raise ArgumentError, 'pass pkey or by:, not both' unless ([pkey, by] - [NoArg]).size == 1
      return model_result { scope.find(pkey) } unless pkey == NoArg

      model_result { scope.find_by!(**by) }
    end

    # create a record with the input <attrs>
    # returns Success(model), Failure(input) if Input object given, or Failure(error)
    def create(input)
      model_result(input: input) { record_class.create(**input) }
    end

    # update the record found with pkey, with input <attrs>
    # returns Success(model), Failure(input) if Input object given, or Failure(error)
    def update(pkey, input)
      model_result input: input, transaction: true do
        scope.find(pkey).tap do |record|
          record.update!(**input)
        end
      end
    end

    # find or initialize record by: <attrs>, updating with input: <attrs>
    # returns Success(model), Failure(input) if Input object given, or Failure(error)
    def upsert(input_arg = nil, input: input_arg, by:)
      model_result input: input, transaction: true do
        record_class.find_or_initialize_by(**by).tap do |record|
          record.update!(**input) if input
        end
      end
    end

    # destory the record found by id:
    # returns Success(model), or Failure(error)
    def destroy(pkey)
      model_result transaction: true do
        scope.find(pkey).tap(&:destroy!)
      end
    end

    # returns List(models)
    def all = list(scope.all)

    # this is done automatically for methods defined on your own repos, but its more performant to set this up
    # here for the abstract repo
    class << self
      delegate :find, :create, :update, :upsert, :destroy, :all, to: :instance
    end

    # Return failure with the exception message for not found error
    exception ActiveRecord::RecordNotFound, -> { _1.message }

    # handle postgres RecordNotUnique as :taken error
    exception ActiveRecord::RecordNotUnique do |exception|
      if attribute = exception.message[/Key .*?(\w+)\)?=/, 1]
        { attribute => :taken }
      else
        exception.message
      end
    end

    # handle postgres null violation as :blank error
    exception ActiveRecord::NotNullViolation do |exception|
      if attribute = exception.message[/column "(\w+)"/, 1]
        { attribute => :blank }
      else
        exception.message
      end
    end
  end
end
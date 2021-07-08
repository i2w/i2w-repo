# frozen_string_literal: true

require 'active_model'
require 'i2w/data_object'
require_relative 'repo/class'
require_relative 'input/with_model'

module I2w
  # Input base class.
  class Input < DataObject::Mutable
    extend Repo::Class
    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks

    class Error < RuntimeError; end

    class InvalidAttributesError < Error; end

    class ValidationContextUnsupportedError < Error; end

    # return an input initialized from a model, and with the model in a tuple object
    def self.with_model(model) = WithModel.new(new(**model), model)

    # we are more permissive with input than a standard DataObject
    def initialize(object = {})
      super(**self.class.to_attributes_hash(object))
    end

    # sometimes we need to transfer errors from after validation, such as db contraint errors
    def errors=(other)
      errors.copy!(other)
    end

    def valid?(context = nil)
      raise ValidationContextUnsupportedError unless context.nil?

      super
    end

    # we raise an error if we attempt to access attributes on an invalid input
    def attributes
      raise InvalidAttributesError unless valid?

      super
    end

    alias to_hash attributes
    alias to_h attributes

    def to_input = self

    def persisted? = false
  end
end

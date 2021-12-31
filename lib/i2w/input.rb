# frozen_string_literal: true

require 'active_model'
require 'i2w/data_object'
require_relative 'input/with_attributes'

module I2w
  # Input base class.
  class Input < DataObject::Mutable
    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks

    # we are more permissive with input than a standard DataObject
    def initialize(object = {})
      super(**self.class.to_attributes_hash(object))
    end

    # sometimes we need to transfer errors from after validation, such as db contraint errors
    def errors=(other)
      errors.copy!(other)
    end

    # we don't support rails validation contexts, just make a different input class
    def valid?(context = nil)
      raise ValidationContextUnsupportedError unless context.nil?

      super
    end

    # the attributes intended for output, this method will return valid and inavlid attributes,
    # used by the #attributes method which ensures attributes are valid
    def attributes_hash = attribute_names.to_h { [_1, send(_1)] }

    # we raise an error if we attempt to access attributes on an invalid input
    def attributes
      raise InvalidAttributesError unless valid?

      attributes_hash
    end

    alias to_hash attributes
    alias to_h attributes

    delegate :[], to: :attributes_hash

    def persisted? = false

    def with(attrs = {}) = WithAttributes.new(dup, **attrs)

    class Error < RuntimeError; end

    class InvalidAttributesError < Error; end

    class ValidationContextUnsupportedError < Error; end
  end
end

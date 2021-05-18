# frozen_string_literal: true

require 'active_model'
require 'i2w/data_object'
require_relative 'repo/class'

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

    class << self
      # we are more permissive with input than a standard DataObject
      def new(object = {})
        super(**to_attributes_hash(object))
      end

      # to keep a reference to the underlying model, use this method
      # this undelying model reference can be used to check if an input corresponds to a persisted object,
      # and the generate routing paths
      def from_model(model)
        new(**model).tap { |input| input.send(:set_model, model) }
      end
    end

    # sometimes we need to transfer errors from after validation, such as db contraint errors
    def errors=(other)
      errors.copy!(other)
    end

    def valid?(context = nil)
      raise ValidationContextUnsupportedError unless context.nil?

      super
    end

    # we raise an error if we attempt to access attributes on an invalid object
    def to_hash
      raise InvalidAttributesError unless valid?

      super
    end
    alias attributes to_hash

    def to_input
      self
    end

    def persisted?
      false
    end

    def model
      @_model
    end

    private

    def set_model(model)
      @_model = model
    end
  end
end

# frozen_string_literal: true

require 'active_model'
require 'i2w/data_object'

module I2w
  # Input base class.
  class Input < DataObject::Mutable
    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks

    class Error < RuntimeError; end

    class InvalidAttributesError < Error; end

    class ValidationContextUnsupportedError < Error; end

    def valid?(context = nil)
      raise ValidationContextUnsupportedError unless context.nil?

      super
    end

    def to_hash
      raise InvalidAttributesError unless valid?

      super
    end
    alias attributes to_hash

    def persisted?
      false
    end
  end
end

# frozen_string_literal: true

module I2w
  # Decorate an input with extra attributes, useful for sending non-input attributes to repository methods
  # see Input#with
  class Input < DataObject::Mutable
    class WithAttributes < SimpleDelegator
      def initialize(input, **attributes)
        @attributes = attributes
        super(input)
      end

      def with(attrs = {}) = __getobj__.with(**@attributes, **attrs)

      def attributes = { **__getobj__.attributes, **@attributes }

      alias delegator_class class

      def class = __getobj__.class

      alias to_h attributes
      alias to_hash attributes
    end
  end
end
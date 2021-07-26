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

      def with(attrs = {}) = super(**@attributes, **attrs)

      def attributes = { **super, **@attributes }

      alias to_h attributes
      alias to_hash attributes
    end
  end
end
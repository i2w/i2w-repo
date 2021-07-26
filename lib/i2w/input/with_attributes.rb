# frozen_string_literal: true

module I2w
  # allows decorating an input with extra attributes
  class Input < DataObject::Mutable
    class WithAttributes < SimpleDelegator
      def initialize(input, **attributes)
        @attributes = attributes
        super(input)
      end

      def attributes = { **super, **@attributes }

      alias to_h attributes
      alias to_hash attributes
    end
  end
end
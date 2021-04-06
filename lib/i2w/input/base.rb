# frozen_string_literal: true

module I2w
  module Input
    # input base class
    class Base < DataObject::Mutable
      extend ActiveModel::Callbacks
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include ActiveModel::Validations::Callbacks

      def valid?(context = nil)
        raise ValidationContextUnsupportedError unless context.nil?

        super
      end

      def to_hash
        raise InvalidAttributesError unless valid?

        super
      end
      alias attributes to_hash
    end
  end
end

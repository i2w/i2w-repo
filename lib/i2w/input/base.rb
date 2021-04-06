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

      def attributes
        raise InvalidAttributesError unless valid?

        instance_values.symbolize_keys.slice(*self.class.attribute_names)
      end
      alias to_hash attributes
    end
  end
end

# frozen_string_literal: true

module I2w
  module Model
    # Base model
    class Base < DataObject::Immutable
      attribute :id
      attribute :updated_at
      attribute :created_at

      def to_param
        id.to_s
      end
    end
  end
end

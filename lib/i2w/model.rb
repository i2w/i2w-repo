# frozen_string_literal: true

require 'i2w/data_object'

module I2w
  # base model class
  class Model < DataObject::Immutable
    attribute :id
    attribute :updated_at
    attribute :created_at

    def to_param
      id.to_s
    end
  end
end

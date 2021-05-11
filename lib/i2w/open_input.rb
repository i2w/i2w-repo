require_relative 'input'

module I2w
  # OpenInput allows an object to be initialized with an arbitrary attributes hash.
  class OpenInput < Input
    def self.to_attributes_hash(object = {})
      object.to_hash.symbolize_keys
    end

    def initialize(**attributes)
      singleton_class.define_method(:attribute_names) { attributes.keys }
      singleton_class.attr_accessor(*attributes.keys)

      super(**attributes)
    end
  end
end

# frozen_string_literal: true

require 'i2w/data_object/missing_attribute'

module I2w
  # represents an model attribute that is intentionally not loaded by the Repository, for example an association
  # or expensive attribute that is not always needed. It is descended from DataObject::MissingAttribute so that
  # attribute defaults will be triggered
  #
  # Avoid having too many of these, prefering to make a new model class fit for the purpose
  #
  # An UnloadedAttribute is treated as a blank attribute as per rails conventions
  class UnloadedAttribute
    include DataObject::MissingAttribute::Protocol

    class Error < RuntimeError; end

    def initialize(model_class, name)
      @model_class = model_class
      @name = name
    end

    def ==(other) = other.is_a?(self.class) && to_s == other.to_s

    alias eql? ==

    def to_s = "<unloaded #{@model_class}##{@name}>"

    alias inspect to_s

    def nil? = true

    def present? = false

    def blank? = true

    def method_missing(*args)
      raise Error, "#{to_s} received ##{args[0]}(#{args[1..]})"
    end
  end
end
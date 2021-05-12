# frozen_string_literal: true

require 'active_support/all'

module I2w
  module Repo
    # given a class, and a type, return the associated class.  Requires klass to have either #repo_class_type defined,
    # or #model_class defined.
    # TODO: add a registry for non conventional use
    module LookupClass
      class << self
        def call(klass, type = :model)
          @associated_classes ||= Hash.new { |m, args| m[args] = associated_class_for(*args) }
          @associated_classes[[klass, type]]
        end

        def associated_class_for(klass, type)
          return klass if klass.repo_class_type == type

          model_class = model_class_for(klass)
          return model_class if type == :model

          "#{model_class}#{type.to_s.camelize}".constantize
        end

        def model_class_for(klass)
          return klass.model_class if klass.respond_to?(:model_class)
          return klass if klass.repo_class_type == :model

          default_model_class_for(klass)
        end

        def default_model_class_for(klass)
          klass.name.sub(/#{klass.repo_class_type.to_s.camelize}\z/, '').constantize
        end
      end
    end
  end
end

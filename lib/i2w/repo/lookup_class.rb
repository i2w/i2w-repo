# frozen_string_literal: true

require 'active_support/all'

require_relative 'missing_class'

module I2w
  module Repo
    # given a class, and a type, return the associated class.  Requires klass to have either #repo_class_type defined,
    # or #model_class defined.
    # TODO: add a registry for non conventional use
    module LookupClass
      class << self
        def call(klass, type = :model)
          unless klass.respond_to?(:repo_class_type) || klass.respond_to?(:model_class)
            raise ArgumentError, 'klass must respond to #repo_class_type or #model_class'
          end

          return klass if klass.respond_to?(:repo_class_type) && klass.repo_class_type == type

          model_class = model_class_for(klass)
          return model_class if type == :model

          class_name = "#{model_class}#{type.to_s.camelize}"
          class_name.constantize
        rescue NameError => e
          MissingClass.new(class_name, type: type, error: e)
        end

        def model_class_for(klass)
          return klass.model_class if klass.respond_to?(:model_class)
          return klass if klass.repo_class_type == :model

          default_model_class_for(klass)
        end

        def default_model_class_for(klass)
          class_name = klass.name.sub(/#{klass.repo_class_type.to_s.camelize}\z/, '')
          class_name.constantize
        rescue NameError => e
          MissingClass.new(class_name, type: :model, error: e)
        end
      end
    end
  end
end

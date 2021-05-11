# frozen_string_literal: true

require 'active_support/all'

module I2w
  module Repo
    # given a class, and a type, return the associated class.  Requires klass to have #model_class defined.
    # TODO: add a  registry for non conventional use
    module AssociatedClass
      class << self
        def call(klass, type = :model)
          @classes_memo ||= Hash.new { |m, args| m[args] = associated_class(*args) }
          @classes_memo[[klass, type]]
        end
        alias [] call

        private

        def associated_class(klass, type)
          suffix = type.to_s == 'model' ? '' : type.to_s.camelize
          "#{klass.model_class}#{suffix}".constantize
        end
      end
    end
  end
end

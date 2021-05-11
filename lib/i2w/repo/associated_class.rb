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

      module Extension
        class << self
          def new(*types, **readers)
            Module.new.tap do |ext|
              (types | readers.keys).each do |type|
                attr = "#{type}_class"
                reader = readers.fetch(type) { proc { AssociatedClass.call(self, type) } }
                ext.define_method attr do
                  instance_variable_get("@#{attr}") || instance_variable_set("@#{attr}", instance_exec(&reader))
                end
                ext.module_eval { private attr_writer attr }
              end
              ext.define_singleton_method(:extended) { _1.const_set('GeneratedAssociatedClassMethods', self) }
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative 'associated_class'

module I2w
  module Repo
    module ClassAccessor
      def repo_class_accessor(*types, **readers)
        (types | readers.keys).each do |type|
          attr = "#{type}_class"
          reader = readers.fetch(type) { proc { AssociatedClass.call(self, type) } }
          define_singleton_method attr do
            instance_variable_get("@#{attr}") || instance_variable_set("@#{attr}", instance_exec(&reader))
          end
          singleton_class.module_eval { private attr_writer attr }
        end
      end
    end
  end
end

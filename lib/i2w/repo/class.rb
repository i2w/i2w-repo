# frozen_string_literal: true

require 'active_support/all'
require_relative 'lookup_class'

module I2w
  module Repo
    module Class
      def self.extended(base)
        repo_class_type = base.name.demodulize.underscore.split('_').last.underscore.to_sym
        base.define_singleton_method(:repo_class_type) { repo_class_type }
      end

      def repo_class_accessor(*types, **readers)
        readers[:model] ||= proc { LookupClass.default_model_class_for(self) } if types.include?(:model)
        (types | readers.keys).each do |type|
          define_repo_class_accessor(type, readers[type])
        end
      end

      private

      def define_repo_class_accessor(type, reader = nil)
        attr = "#{type}_class"
        reader ||= proc { Repo.lookup(self, type) }
        define_singleton_method attr do
          instance_variable_get("@#{attr}") || instance_variable_set("@#{attr}", instance_exec(&reader))
        end
        singleton_class.module_eval { private attr_writer attr }
      end

      def model_class=(model_class)
        define_singleton_method(:model_class) { model_class }
      end
    end
  end
end

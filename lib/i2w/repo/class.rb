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

      def repo_class_accessor(*types, **defaults)
        defaults[:model] ||= proc { LookupClass.default_model_class_for(self) } if types.include?(:model)

        (types | defaults.keys).each { |type| define_repo_class_accessor(type, defaults[type]) }
      end

      private

      def define_repo_class_accessor(type, default = nil)
        attr = "#{type}_class"
        default ||= proc { Repo.lookup(self, type) }

        define_singleton_method("#{attr}=") do |klass|
          define_singleton_method(attr) { klass }
        end

        singleton_class.module_eval { private "#{attr}=" }

        define_singleton_method(attr) do
          instance_exec(&default).tap { |klass| define_singleton_method(attr) { klass } }
        end
      end

      def model_class=(model_class)
        define_singleton_method(:model_class) { model_class }
      end
    end
  end
end

# frozen_string_literal: true

require 'active_support/all'

module I2w
  module Repo
    # extend into a repo base class that is not Model
    module Class
      class << self
        def lookup(ref, type)
          return ref if ref.respond_to?(:repo_class_type) && ref.repo_class_type == type
          return ref.lookup(type) if ref.instance_of?(Ref)

          class_reader = :"#{type}_class"
          return ref.send(class_reader) if ref.respond_to?(class_reader)

          base_name = ref.respond_to?(:repo_class_base_name) ? ref.repo_class_base_name : ref.name
          Ref.new(base_name, type).lookup
        end
      end

      def repo_class_type = name.demodulize.underscore.split('_').last.underscore.to_sym

      def repo_class_base_name = name.sub(/#{repo_class_type.to_s.camelize}\z/, '')

      def repo_base(class_name) = define_singleton_method(:repo_class_base_name) { class_name.to_s }

      def repo_class_accessor(*types, **defaults)
        (types | defaults.keys).each { |type| define_repo_class_accessor(type, defaults[type]) }
      end

      private

      def define_repo_class_accessor(type, default = nil)
        attr = "#{type}_class"
        default ||= proc { Ref.new(repo_class_base_name, type).lookup }
        default = proc { default } unless default.respond_to?(:call)

        define_singleton_method("#{attr}=") do |klass|
          define_singleton_method(attr) { klass }
        end

        singleton_class.module_eval { private "#{attr}=" }

        define_singleton_method(attr) do
          instance_exec(&default).tap { |klass| define_singleton_method(attr) { klass } }
        end
      end

      # used in place of a conventional class which can't be found, be other classes can still be derived from it
      class Ref
        attr_reader :base_name, :type

        def initialize(base_name, type)
          raise ArgumentError, 'pass string, and symbol' unless base_name.is_a?(String) && type.is_a?(Symbol)

          @base_name = base_name
          @type = type
        end

        def to_s
          "#{self.class.name}[#{base_name} :#{type}]"
        end

        def lookup(type = self.type)
          class_name = type == :model ? base_name : "#{base_name}#{type.to_s.camelize}"
          class_name.constantize
        rescue NameError
          Ref.new(base_name, type)
        end

        def respond_to_missing?(...) = true

        def method_missing(...) = raise(NotFoundError, self)

        # raised when a Class::Ref is accessed as a class
        class NotFoundError < RuntimeError
          attr_reader :ref

          def initialize(ref)
            @ref = ref
            super "#{ref} was accessed, but it was not found"
          end
        end
      end
    end
  end
end

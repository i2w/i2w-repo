# frozen_string_literal: true

require 'active_support/all'

module I2w
  module Repo
    # provides lookup and configuration of repo base classes
    module Base
      class << self
        def conventions = @conventions ||= {}

        def lookup(ref, type, *args)
          return ref.send("#{type}_class", *args) if ref.respond_to?("#{type}_class")

          base_lookup(ref, type, *args)
        end

        def base_lookup(ref, type, *args)
          return ref if ref.respond_to?(:repo_type) && ref.repo_type == type && args.empty?
          return ref.lookup(type, *args) if ref.respond_to?(:lookup)

          base = ref.respond_to?(:repo_base) ? ref.repo_base : ref.to_s
          Ref.new(base, type).lookup(type, *args)
        end

        def extension(type, accessors: [], from_base: nil, to_base: nil, search_namespaces: false)
          from_base ||= proc { "#{_1}#{type.to_s.camelize}" }
          to_base   ||= proc { _1.sub(/#{type.to_s.camelize}\z/, '') }

          conventions[type] = { from_base: from_base, search_namespaces: search_namespaces }

          Module.new.tap do
            define_repo_methods(_1, type, to_base)
            define_accessors(_1, accessors)
          end
        end

        private

        def define_repo_methods(extension, type, to_base)
          extension.define_method(:repo_type) { type }
          extension.define_method(:repo_base) do |class_name = nil|
            @repo_base = class_name.to_s if class_name
            @repo_base ||= to_base.call(name)
          end
        end

        def define_accessors(extension, types)
          if types.last.is_a?(Hash)
            *types, values = types
          else
            values = {}
          end
          (types | values.keys).each { |type| define_accessor(extension, type, values[type]) }
        end

        def define_accessor(extension, type, value = nil)
          attr = "#{type}_class"
          value ||= -> { Base.base_lookup(self, type) }
          value = -> { value } unless value.respond_to?(:call)

          extension.define_method("#{attr}=") { instance_variable_set :"@#{attr}", _1 }
          extension.module_eval { private "#{attr}=" }
          extension.define_method(attr) do
            instance_variable_get(:"@#{attr}") || instance_variable_set(:"@#{attr}", instance_exec(&value))
          end
        end
      end

      # a reference to a repo class, other classes can still be derived from it if it isn't defined
      class Ref
        attr_reader :base, :type

        def initialize(base, type)
          raise ArgumentError, 'pass string [, symbol]' unless base.is_a?(String) && type.is_a?(Symbol)

          @base = base
          @type = type
        end

        def to_s = "#{self.class.name}[#{base} :#{type}]"

        def lookup(type, *args)
          class_name = base_to_class_name(type, *args)
          klass = search_namespaces? ? try_namespaced_constantize(class_name) : try_constantize(class_name)
          klass || self.class.new(base, type)
        end

        def base_to_class_name(type, *args) = Base.conventions.fetch(type).fetch(:from_base).call(base, *args)

        def search_namespaces? = Base.conventions.fetch(type).fetch(:search_namespaces)

        def try_constantize(class_name)
          class_name.constantize
        rescue NameError
          nil
        end

        def try_namespaced_constantize(class_name)
          parts = class_name.split('::')
          candidates = parts.length.times.map { parts[_1..].join('::').to_s }
          candidates.each do |candidate|
            return candidate.constantize
          rescue NameError
            nil
          end
          nil
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

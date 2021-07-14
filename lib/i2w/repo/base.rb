# frozen_string_literal: true

require 'active_support/all'

module I2w
  module Repo
    # provides lookup and configuration of repo base classes
    module Base
      class << self
        def converters = @converters ||= {}

        def lookup(ref, type, *args)
          return ref.send("#{type}_class", *args) if ref.respond_to?("#{type}_class")

          base_lookup(ref, type, *args)
        end

        def base_lookup(ref, type, *args)
          return ref if ref.respond_to?(:repo_type) && ref.repo_type == type && args.empty?
          return ref.lookup(type, *args) if ref.respond_to?(:lookup)

          base = ref.respond_to?(:repo_base) ? ref.repo_base : ref.to_s
          Ref.new(base).lookup(type, *args)
        end

        def extension(type, from_base:, to_base:, accessors: [])
          converters[type] = { from_base: from_base, to_base: to_base }

          Module.new.tap do
            define_repo_methods(_1, type)
            define_accessors(_1, accessors)
          end
        end

        private

        def define_repo_methods(extension, type)
          extension.define_method(:repo_type) { type }
          extension.define_method(:repo_base) do |base = nil|
            @repo_base = base.to_s if base
            @repo_base ||= Base.converters.fetch(type)[:to_base].call(name)
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
          value ||= ->(*args) { Base.base_lookup(self, type, *args) }
          value = -> { value } unless value.respond_to?(:call)

          extension.define_method("#{attr}=") { instance_variable_set :"@#{attr}", _1 }
          extension.module_eval { private "#{attr}=" }
          extension.define_method(attr) do |*args|
            instance_variable_get(:"@#{attr}") || instance_exec(*args, &value)
          end
        end
      end

      # a reference to a repo class, other classes can still be derived from it if it isn't defined
      class Ref
        attr_reader :base

        def initialize(base)
          raise ArgumentError, 'pass string' unless base.is_a?(String)

          @base = base
        end

        def to_s = "#{self.class.name}[#{base}]"

        def lookup(type, *args)
          try_constantize(base_to_class_name(type, *args)) || self
        end

        def base_to_class_name(type, *args) = Base.converters.fetch(type).fetch(:from_base).call(base, *args)

        def try_constantize(class_name)
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

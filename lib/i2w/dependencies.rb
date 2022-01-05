# frozen_string_literal: true

require 'i2w/lazy'
require_relative 'class_lookup'

module I2w
  # extension that provides class declared late binding dependencies with defaults, which may be overridden on
  # an instance.
  #
  # combined with I2w::ClassLookup this provides the mechanism for conventionally named classes to connect to each other
  #
  # adding a dependency creates a private class and instance reader method for the dependency by default
  #
  # To resolve the dependencies to a hash, use dependencies.resolve_all(instance, **override)
  module Dependencies
    def self.extended(into)
      raise ArgumentError, "#{self} is be a class extension, but #{into} is not a class" unless into.is_a?(Class)

      into.instance_variable_set(:@dependencies, Container.new)
      into.prepend Override
    end

    attr_reader :dependencies

    protected

    # adds the dependency and a late binding class reader and instance reader
    # to add a dependency without readers just use dependencies.add(dep, default)
    def dependency(dep, default, public: false, class_only: false)
      define_dependency_readers(dep.to_sym, public, class_only)
      dependencies.add(dep, default)
    end

    def class_lookup(...) = -> { ClassLookup.new(...).call(_1) }

    private

    def inherited(subclass)
      subclass.instance_variable_set(:@dependencies, dependencies.dup)
      super
    end

    def define_dependency_readers(dep, public, class_only)
      class_eval "def self.#{dep} = @#{dep} ||= dependencies.resolve(self, :#{dep})", __FILE__, __LINE__
      private_class_method dep unless public

      unless class_only
        class_eval "def #{dep} = @#{dep} || self.class.send(:#{dep})", __FILE__, __LINE__
        private dep unless public
      end
    end

    # module prepend to override dependencies on our instance if they are passed as kwargs, and if instance
    # readers have been defined for those dependencies
    module Override
      def initialize(*args, **kwargs)
        overridden = self.class.dependencies.keys.select do
          instance_variable_set("@#{_1}", kwargs[_1]) if kwargs.key?(_1) && respond_to?(_1, true)
        end

        super(*args, **kwargs.except(*overridden))
      end
    end

    # holds the dependency keys and default values, and handles resolving the values
    class Container
      def initialize
        @container = {}
      end

      def initialize_copy(source)
        @container = source.instance_variable_get(:@container).dup
      end

      def keys = @container.keys

      def add(name, default) = @container[name.to_sym] = Lazy.new(default)

      def resolve(context, key) = @container.fetch(key).resolve(context)

      def resolve_all(context) = keys.to_h { [_1, resolve(context, _1)] }
    end
  end
end
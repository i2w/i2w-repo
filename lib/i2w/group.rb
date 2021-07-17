# frozen_string_literal: true

module I2w
  # Allows a group of classes that are related by a type to be looked up from each other
  class Group
    attr_reader :registry

    def initialize
      @registry = {}
    end

    def lookup(from, type, *args)
      return from.send("#{type}_class", *args) if from.respond_to?("#{type}_class")

      group_lookup(from, type, *args)
    end

    def group_lookup(from, type, *args)
      group_name = from.respond_to?(:group_name) ? from.group_name : from.to_s
      return from.group_lookup(group_name, type, *args) if from.respond_to?(:group_lookup)

      klass = registry.fetch(type)
      klass.from_group_name(group_name, *args)
    rescue NameError => e
      MissingClass.new(e, group_name, type, *args)
    end

    def register(klass, type = nil, accessors: [], &block)
      registry[type] = klass if type
      extension = GeneratedMethods.call(self, type, accessors, &block)
      extension_name = "#{type}_generated_group_methods".camelize
      klass.const_set(extension_name, extension)
      klass.extend extension
    end

    class MissingClass #:nodoc:
      attr_reader :exception, :group_name, :args

      def initialize(exception, group_name, *args)
        @exception = exception
        @group_name = group_name
        @args = args
      end

      def method_missing(method, ...)
        raise @exception
      rescue StandardError => e
        raise "Undefined #{group_name} #{args.join(',')} received ##{method}\nOrigin: #{e.message}"
      end

      def respond_to_missing?(...) = true
    end

    module GeneratedMethods #:nodoc:
      class << self
        def call(group, type, accessors, &block)
          Module.new.tap do |ext|
            ext.module_eval(&block) if block

            ext.define_method(:group) { group }
            ext.define_method(:group_name=) { |name| define_singleton_method(:group_name) { name.to_s } }
            ext.module_eval { private :group, :group_name= }

            if type
              ext.define_method(:group_type) { type }
              def_group_name(ext, type)      unless ext.method_defined?(:group_name)
              def_from_group_name(ext, type) unless ext.method_defined?(:from_group_name)
            end

            def_accessors(ext, group, accessors)
          end
        end

        private

        def def_group_name(ext, type)
          camelized_type = type.to_s.camelize
          ext.define_method(:group_name) { name.sub(/#{camelized_type}\z/, '') }
        end

        def def_from_group_name(ext, type)
          camelized_type = type.to_s.camelize
          ext.define_method(:from_group_name) { |name| "#{name}#{camelized_type}".constantize }
        end

        def def_accessors(ext, group, types)
          values = {}
          (*types, values = types) if types.last.is_a?(Hash)
          (types | values.keys).each { |type| def_accessor(ext, group, type, values[type]) }
        end

        def def_accessor(ext, group, type, value = nil)
          attr = "#{type}_class"
          value ||= ->(*args) { group.group_lookup(self, type, *args) }

          ext.define_method("#{attr}=") { instance_variable_set :"@#{attr}", _1 }
          ext.module_eval { private "#{attr}=" }
          ext.define_method(attr) { |*args| instance_variable_get(:"@#{attr}") || instance_exec(*args, &value) }
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative '../record/to_hash'
require_relative '../unloaded_attribute'

module I2w
  class Repo
    # configuration container for repository instance
    class Config
      def initialize
        @only_attributes = nil
        @except_attributes = nil
        @always_attributes = []
        @optional_attributes = {}
        @optional_scopes = {}
      end

      def initialize_dup(src)
        @only_attributes     = src.only_attributes.dup
        @except_attributes   = src.except_attributes.dup
        @always_attributes   = src.always_attributes.dup
        @optional_attributes = src.optional_attributes.dup
        @optional_scopes     = src.optional_scopes.dup
      end

      attr_reader :only_attributes, :except_attributes, :always_attributes, :optional_attributes, :optional_scopes

      def optional_keys = optional_attributes.keys

      def attributes(only: NoArg, except: NoArg)
        @only_attributes = only unless only == NoArg
        @except_attributes = except unless except == NoArg
      end

      def optional(name, loader = name, attributes: { name => loader }, scope: NoArg)
        optional_attributes_hash = to_optional_attributes_hash(attributes)

        always_attributes.concat optional_attributes_hash.keys
        optional_attributes[name.to_sym] = optional_attributes_hash
        optional_scopes[name.to_sym] = scope unless scope == NoArg
      end

      # return a Record::ToHash object that will be used by the repository to convert the record into model attributes
      # specify with: to include optional attribute loaders
      def record_to_hash(model_class, with: nil)
        Record::ToHash.new only: only_attributes, except: except_attributes, always: always_attributes,
                           extra: attributes_with(with),
                           on_missing: -> { UnloadedAttribute.new model_class, _1 }

      end

      # return an ActiveRecord scope (by default the record_class) that is used by the repository to find records
      # specify with: to apply optional scopes
      def scope(record_class, with: nil) = scope_with(record_class, with)

      # assert that this config defines optionals specified, return array
      def assert_optional!(*with)
        unknown = with - optional_keys
        raise ArgumentError, "unnkown: #{unknown.join(', ')} (defined: #{optional_keys.join(', ')})" if unknown.any?

        with
      end

      private

      def attributes_with(with)
        optional_attributes.slice(*with).values.reduce({}) do |a, extra|
          a.merge!(extra)
        end
      end

      def scope_with(scope, with)
        optional_scopes.slice(*with).values.reduce(scope) do |s, apply|
          apply.arity == 1 ? apply.call(s) : s.instance_exec(&apply)
        end
      end

      def to_optional_attributes_hash(attributes)
        return {} if attributes == NoArg
        return attributes.transform_values(&:to_proc) if attributes.is_a?(Hash)

        attributes = Array(attributes)
        last_hash = attributes.last.is_a?(Hash) ? attributes.pop : {}
        { **attributes.to_h { [_1, _1.to_proc] }, **last_hash.transform_values(&:to_proc) }
      end
    end
  end
end
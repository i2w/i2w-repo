# frozen_string_literal: true

require 'i2w/rescue_as_failure'
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
        @default_order = nil
        @rescue_as_failure = RescueAsFailure.new
      end

      def initialize_dup(src)
        @only_attributes     = src.only_attributes.dup
        @except_attributes   = src.except_attributes.dup
        @always_attributes   = src.always_attributes.dup
        @optional_attributes = src.optional_attributes.dup
        @optional_scopes     = src.optional_scopes.dup
        @default_order       = src.default_order.dup
        @rescue_as_failure   = src.rescue_as_failure.dup
      end

      attr_reader :only_attributes,
                  :except_attributes,
                  :always_attributes,
                  :optional_attributes,
                  :optional_scopes,
                  :rescue_as_failure

      def exception(...) = rescue_as_failure.add(...)

      def default_order(*val)
        @default_order = val if val.any?
        @default_order
      end

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
        with_keys, _ = keys_and_options(with)
        unknown      = with_keys - optional_attributes.keys
        if unknown.any?
          raise ArgumentError, "unknown option(s): #{unknown.join(', ')} (not in: #{optional_attributes.keys.inspect})"
        end

        with
      end

      private

      def attributes_with(with)
        with_keys, nested_with = keys_and_options(with)

        optional_attributes.slice(*with_keys).each_with_object({}) do |(key, extra), result|
          extra.each do |attr, loader|
            if loader.arity == 2
              nested_with_for_key = nested_with[key]
              result[attr] = ->(record) { loader.call(record, nested_with_for_key) }
            else
              result[attr] = loader
            end
          end
        end
      end

      def scope_with(scope, with)
        with_keys, nested_with = keys_and_options(with)

        optional_scopes.slice(*with_keys).reduce(scope) do |s, (key, apply)|
          case apply.arity
          when 2 then apply.call(s, nested_with[key])
          when 1 then apply.call(s)
          else        s.instance_exec(&apply)
          end
        end
      end

      def to_optional_attributes_hash(attributes)
        return {} if attributes == NoArg
        return attributes.transform_values(&:to_proc) if attributes.is_a?(Hash)

        attributes = Array(attributes)
        last_hash = attributes.last.is_a?(Hash) ? attributes.pop : {}
        { **attributes.to_h { [_1, _1.to_proc] }, **last_hash.transform_values(&:to_proc) }
      end

      # given an array with options as last argument, return all keys, and options
      # eg:
      #   keys_and_options([:a, :b, c: 1]) # => [[:a, :b, :c], { c: 1 }]
      def keys_and_options(ary)
        ary = ary.dup
        options = ary.last.is_a?(Hash) ? ary.pop : {}
        [[*ary, *options.keys], options]
      end
    end
  end
end
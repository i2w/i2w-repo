# frozen_string_literal: true

require 'i2w/no_arg'

require_relative 'missing_class'

module I2w
  # lookup an associated class, using a block that transforms the class name.
  # If it cant be found return a MissingClass object, which can still be used for further lookups
  # but will raise an error if any other methods are called on it.
  # You can specify multiple lookups, useful for looking up a specialized class, but falling back to a general class.
  class ClassLookup
    class << self
      def call(source, ...) = new(...).call(source)

      def resolve(lookup)
        return lookup if lookup.is_a?(Class)
        lookup = new(lookup.to_s) unless lookup.is_a?(self)
        lookup.call
      end

      alias [] resolve
    end

    def initialize(*lookups, &lookup)
      @source = NoArg
      @lookups = [*lookups, lookup].compact
    end

    def source(source) = tap { @source = source }

    def call(source = NoArg)
      raise ArgumentError, 'No lookups provided' if @lookups.size == 0
      source = @source if source == NoArg
      class_name = resolve_lookup(lookup, source)
      class_name.to_s.constantize

    rescue NameError => e
      class_name ||= e.message[/constant (.*)/, 1]
      missing = MissingClass.new(*@missing&.class_names, class_name)

      if lookups.size > 1
        self.class.new(*lookups[1..]).source(source).missing(missing).call
      else
        missing
      end
    end

    def on_missing(&lookup)
      @lookups << lookup
      self
    end

    protected

    def lookup = @lookups.first

    attr_reader :lookups

    def missing(missing) = tap { @missing = missing }

    private

    def resolve_lookup(lookup, source)
      return lookup if [Symbol, String, Class, MissingClass].include?(lookup.class)
      return lookup.call if lookup.arity == 0
      raise ArgumentError, "source required for lookup: #{lookup}" if source == NoArg

      source = source.class unless [Symbol, String, Class, MissingClass].include?(source.class)
      lookup.call source.to_s
    end
  end
end
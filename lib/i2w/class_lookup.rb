# frozen_string_literal: true

require_relative 'missing_class'

module I2w
  # lookup an associated class, using a block that transforms the class name.
  # If it cant be found return a MissingClass object, which can still be used for further lookups
  # but will raise an error if any other methods are called on it.
  # You can specify multiple lookups, useful for looking up a specialized class, but falling back to a general class.
  class ClassLookup

    def self.call(source, ...)
      new(...).call(source)
    end

    def initialize(*lookups, &lookup)
      @lookups = [*lookups, lookup].compact
      raise ArgumentError, 'No lookups provided' if @lookups.size == 0
    end

    def call(source = NoArg)
      class_name = resolve_lookup(lookup, source)
      class_name.to_s.constantize

    rescue NameError
      missing = MissingClass.new(*@missing&.class_names, class_name)

      if lookups.size > 1
        self.class.new(*lookups[1..]).tap { _1.missing = missing }.call(source)
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

    attr_writer :missing

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
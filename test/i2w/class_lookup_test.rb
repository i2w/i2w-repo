require 'test_helper'

require 'i2w/class_lookup'

module I2w
  class ClassLookupTest < ActiveSupport::TestCase
    class Foo; end

    class FooRecord; end

    module Foos
      class IndexAction; end
    end

    test '.new examples' do
      assert_equal FooRecord, ClassLookup.new { _1 + 'Record' }.resolve(Foo)
      assert_equal FooRecord, ClassLookup.new { "#{_1}Record" }.resolve('I2w::ClassLookupTest::Foo')
      assert_equal Foo, ClassLookup.new { _1.deconstantize.singularize }.resolve(Foos::IndexAction)
      assert_equal Foo, ClassLookup.new(-> { Nope }, Foo).resolve
      assert_equal Foo, ClassLookup.new('Nope') { 'I2w::ClassLookupTest::Foo' }.resolve

      error = assert_raises(ArgumentError) { ClassLookup.new.resolve }
      assert_equal "No lookups provided", error.message

      error = assert_raises(ArgumentError) { ClassLookup.new('Nope', -> { _1 }).resolve }
      assert_match(/source required for lookup/, error.message)

      assert_equal MissingClass.new('No', 'NilClassNo'), ClassLookup.new('No', -> { "#{_1}No" }).source(nil).resolve
    end

    test 'implements Lazy::Protocol' do
      actual = ClassLookup.new { _1 + 'Record' }
      assert_equal actual, Lazy.to_lazy(actual)
      assert_equal FooRecord, Lazy.resolve(actual, Foo)
    end

    test 'on_missing' do
      assert_equal FooRecord, ClassLookup.new { _1 + 'Record' }.on_missing { FooRecord }.resolve('Bar')
      assert_equal FooRecord, ClassLookup.new( -> { _1 + 'Record' }, -> { FooRecord }).resolve('Bar')
      assert_equal Foo, ClassLookup.new(&:upcase).on_missing(&:downcase).on_missing { Foo }.resolve(FooRecord)
    end

    test 'Missing class' do
      actual = ClassLookup.new { _1 + 'Floopy' }.resolve(Foo)
      assert_equal MissingClass.new('I2w::ClassLookupTest::FooFloopy'), actual
      assert_equal 'I2w::ClassLookupTest::FooFloopy', actual.to_s
    end

    test 'Missing class keeps track of all attempts' do
      actual = ClassLookup.new { 'Foo' }.on_missing { 'Bar' }.resolve('X')
      assert_equal MissingClass.new('Foo', 'Bar'), actual
      assert_equal 'Bar', actual.to_s
      assert_equal '#<Missing class: Bar (also tried: Foo)>', actual.inspect
    end

    test '.resolve(<thing>) examples' do
      begin self.class.send(:remove_const, :Thing) rescue NameError end

      string = "#{self.class.name}::Thing"
      lookup = ClassLookup.new { Thing }
      missing = ClassLookup.new { Thing }.resolve

      assert_equal MissingClass.new("#{self.class.name}::Thing"), ClassLookup.resolve(string)
      assert_equal MissingClass.new("#{self.class.name}::Thing"), ClassLookup.resolve(lookup)
      assert_equal MissingClass.new("#{self.class.name}::Thing"), ClassLookup.resolve(missing)

      self.class.const_set :Thing, Class.new

      assert_equal Thing, ClassLookup.resolve(string)
      assert_equal Thing, ClassLookup.resolve(lookup)
      assert_equal Thing, ClassLookup.resolve(missing)
      assert_equal Thing, ClassLookup.resolve(Thing)
    end
  end
end
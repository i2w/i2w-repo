require 'test_helper'

require 'i2w/class_lookup'

module I2w
  class ClassLookupTest < ActiveSupport::TestCase
    class Foo; end

    class FooRecord; end

    module Foos
      class IndexAction; end
    end

    test '.call examples' do
      assert_equal FooRecord, ClassLookup.call(Foo) { _1 + 'Record' }
      assert_equal FooRecord, ClassLookup.call(Foo.new) { _1 + 'Record' }
      assert_equal FooRecord, ClassLookup.call(MissingClass.new('I2w::ClassLookupTest::Foo')) { _1 + 'Record' }
      assert_equal FooRecord, ClassLookup.call(Foo) { _1.sub(/\z/, 'Record') }
      assert_equal Foo,       ClassLookup.call(FooRecord) { _1.sub 'Record', '' }
      assert_equal Foo,       ClassLookup.call('I2w::ClassLookupTest::FoosRecord') { _1.sub('Record', '').singularize }
      assert_equal Foo,       ClassLookup.call(Foos::IndexAction) { _1.deconstantize.singularize }
      assert_equal FooRecord, ClassLookup.call(Foos::IndexAction) { _1.deconstantize.singularize + 'Record' }
    end

    test '.new examples' do
      assert_equal FooRecord, ClassLookup.new { _1 + 'Record' }.call(Foo)
      assert_equal FooRecord, ClassLookup.new { "#{_1}Record" }.call('I2w::ClassLookupTest::Foo')
      assert_equal Foo, ClassLookup.new { _1.deconstantize.singularize }.call(Foos::IndexAction)
      assert_equal Foo, ClassLookup.new(-> { Nope }, Foo).call
      assert_equal Foo, ClassLookup.new('Nope') { 'I2w::ClassLookupTest::Foo' }.call

      error = assert_raises(ArgumentError) { ClassLookup.new }
      assert_equal "No lookups provided", error.message

      error = assert_raises(ArgumentError) { ClassLookup.new('Nope', -> { _1 }).call }
      assert_match(/source required for lookup/, error.message)
    end

    test 'on_missing' do
      assert_equal FooRecord, ClassLookup.new { _1 + 'Record' }.on_missing { FooRecord }.call('Bar')
      assert_equal FooRecord, ClassLookup.call('Bar', -> { _1 + 'Record' }, -> { FooRecord })
      assert_equal Foo, ClassLookup.new(&:upcase).on_missing(&:downcase).on_missing { Foo }.call(FooRecord)
    end

    test 'Missing class' do
      actual = ClassLookup.call(Foo) { _1 + 'Floopy' }
      assert_equal MissingClass.new('I2w::ClassLookupTest::FooFloopy'), actual
      assert_equal 'I2w::ClassLookupTest::FooFloopy', actual.to_s
    end

    test 'Missing class keeps track of all attempts' do
      actual = ClassLookup.new { 'Foo' }.on_missing { 'Bar' }.call('X')
      assert_equal MissingClass.new('Foo', 'Bar'), actual
      assert_equal 'Bar', actual.to_s
      assert_equal '#<Missing class: Bar (also tried: Foo)>', actual.inspect
    end
  end
end
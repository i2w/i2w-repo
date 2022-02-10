require 'test_helper'

require 'i2w/dependencies'

module I2w
  class DependenciesTest < ActiveSupport::TestCase
    # this is set up like an Action (see i2w-action)
    class Base
      extend Dependencies

      dependency :foo, -> { 'foo' }
      dependency :bar, 'bar', public: true
      dependency :input_class, class_lookup { _1.sub('::DependenciesTest::', '::Other::') + 'Input' }
      dependency :broadcaster_class, class_lookup { "#{_1}Broadcaster" }.on_missing { "#{_1.sub(/::\w+\z/, '')}::Broadcaster" }

      attr_reader :arg, :kwarg

      def initialize(arg = 'default arg', kwarg: 'default kwarg')
        @arg = arg
        @kwarg = kwarg
      end

      def call = "foo: #{foo}, bar: #{bar}"

      def self.call(...) = new.call(...)
    end

    class Other < Base
      dependency :bar, -> { 'BAR' }, public: true
      dependency :record_class, class_lookup { _1 + 'Record' }
      dependency :class_only, "Class only", class_only: true, public: true
    end

    class OtherRecord; end

    class Broadcaster; end

    class OtherBroadcaster; end

    test 'dependencies are available on the class level' do
      assert_equal 'foo', Base.send(:foo)
      assert_equal 'bar', Base.send(:bar)
      assert_equal 'foo', Other.send(:foo)
      assert_equal 'BAR', Other.send(:bar)
    end

    test 'dependency has a default - can be overridden via #set_instance_variables!' do
      assert 'foo: foo, bar: bar', Base.call
      assert 'foo: xxx, bar: bar', Base.new(foo: 'xxx').call
    end

    test 'dependencies have a private class and instance getter' do
      refute Base.respond_to?(:foo, include_private = false)
      assert Base.respond_to?(:foo, include_private = true)
      refute Base.new.respond_to?(:foo, include_private = false)
      assert Base.new.respond_to?(:foo, include_private = true)
    end

    test 'dependencies have no setters' do
      refute Base.new.respond_to?(:foo=, include_private = true)
    end

    test 'dependencies are inherted, but can be overridden' do
      assert 'foo: foo, bar: BAR', Other.call
      assert 'foo: xxx, bar: yyy', Other.new(foo: 'xxx', bar: 'yyy').call
    end

    test 'class_only dependency does not add instance method, and cannot be set on the instance' do
      assert 'Class only', Other.class_only
      refute Other.new.respond_to?(:class_only)
      assert_raises ArgumentError do
        Other.new(class_only: 'nope')
      end
    end

    test 'class_lookup looks up classes correctly' do
      assert_equal MissingClass.new('I2w::Other::BaseInput'), Base.new.send(:input_class)
      assert_raises(NoMethodError) { Base.new.send(:record_class) }
      assert_equal MissingClass.new('I2w::Other::OtherInput'), Other.new.send(:input_class)
      assert_equal OtherRecord, Other.new.send(:record_class)
    end

    test 'class_lookup can have #on_missing fallback' do
      assert_equal Broadcaster, Base.send(:broadcaster_class)
      assert_equal OtherBroadcaster, Other.send(:broadcaster_class)
    end

    test 'initialize is called correctly when overriding dependencies' do
      actual = Other.new(bar: 'BIG BAR')
      assert_equal 'BIG BAR', actual.bar
      assert_equal 'default arg', actual.arg
      assert_equal 'default kwarg', actual.kwarg

      actual = Other.new(bar: nil, kwarg: 'X')
      assert_nil actual.bar
      assert_equal 'X', actual.kwarg

      actual = Other.new(9, kwarg: 'X', bar: 'BIG BAR')
      assert_equal 'BIG BAR', actual.bar
      assert_equal 9, actual.arg
      assert_equal 'X', actual.kwarg

      e = assert_raises ArgumentError do
        Other.new(9, kwarg: 'X', bar: 'BIG BAR', unknown: 'x')
      end

      assert_equal "unknown keyword: :unknown (overridable dependencies are: :foo, :bar, :input_class, :broadcaster_class, :record_class)", e.message
    end

    test 'Dependencies::Container #resolve and #set_instance_variables!' do
      callable_0 = Object.new.tap do |obj|
        obj.define_singleton_method(:call) { :callable_0 }
      end

      callable_1 = Object.new.tap do |obj|
        obj.define_singleton_method(:call) { |arg| [:callable_1, arg] }
      end

      instance = Object.new.tap do |obj|
        obj.define_singleton_method(:foo) { :foo_method }
      end

      var_in_outer_scope = 'var_in_outer_scope'
      container = Dependencies::Container.new
      container.add :a, :foo
      container.add :b, callable_0
      container.add :c, callable_1
      container.add :d, ->(instance) { "baz: #{instance.foo}" }
      container.add :e, -> { var_in_outer_scope }
      container.add :f, 'hello'

      assert_equal [:a, :b, :c, :d, :e, :f], container.keys

      resolved = container.resolve_all(instance)

      assert_equal({ a: :foo_method,
                     b: :callable_0,
                     c: [:callable_1, instance],
                     d: "baz: foo_method",
                     e: 'var_in_outer_scope',
                     f: 'hello'}, resolved)

      assert_equal :callable_0, container.resolve(instance, :b)
    end
  end
end
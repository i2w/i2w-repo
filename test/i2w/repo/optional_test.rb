# frozen_string_literal: true

require 'test_helper'

module I2w
  class RepoOptionalTest < ActiveSupport::TestCase
    class FooRepo < Repo
      optional :two
      optional :things, scope: :symbol_scope

      def find_with_things(id:)
        model_result do
          record = scope.find(id)
          { **record, things: record.to_hash.values.reject(&:nil?) }
        end
      end

      def self.symbol_scope(_) = FooRecord
    end

    class FooSubRepo < FooRepo
      dependency :model_class, -> { Foo }
      dependency :record_class, -> { FooRecord }

      optional :three, attributes: [:three]
      optional :things, ->(record) { record.attributes.values.reject(&:nil?) }
    end

    class Foo2Repo < Repo
      dependency :record_class, -> { FooRecord }

      optional :stats, attributes: { even_count: ->(_) { 1 }, odd_count: ->(_) { 2 }, count: ->(_) { 3 } }
      optional :posts, scope: -> { includes(:posts) }
    end

    class Foo < Model
      attribute :one
      attribute :two
      attribute :three
      attribute :things
    end

    class Foo2 < Model
      attribute :one
      attribute :two
      attribute :three
      attribute :even_count
      attribute :odd_count
      attribute :count
      attribute :posts
    end

    class FooRecord
      def initialize(attrs)
        @attrs = attrs
      end

      def posts = @attrs[:posts] || []

      def attributes = @attrs

      alias to_hash attributes

      def self.all = self

      def self.find(id)
        case id
        when 1 then new(one: 1)
        when 13 then new(one: 1, three: 3)
        when 123 then new(one: 1, two: 2, three: 3)
        end
      end

      def self.includes(arg)
        raise ArgumentError, 'must pass :posts in this test' unless arg == :posts
        ScopedToPosts.new(self)
      end

      class ScopedToPosts < SimpleDelegator
        def find(id)
          new(posts: [:post1, :post2], **super)
        end
      end
    end

    test 'optional_attribute replaces missing attributes with unloaded attributes' do
      actual = FooRepo.find_with_things(id: 13)
      assert actual.success?
      assert_equal Foo, actual.value.class
      assert_equal [:one, :two, :three, :things], actual.value.to_h.keys
      assert_equal [1, 3], actual.value.things
      assert_equal UnloadedAttribute.new(Foo, :two), actual.value.two
    end

    test 'optional_attribute does not touch non missing attributes' do
      actual = FooRepo.find(id: 123)
      assert actual.success?
      assert_equal Foo, actual.value.class
      assert_equal({ one: 1, two: 2, three: 3}, actual.value.to_hash.reject { _2.blank? })
    end

    test 'non optional attributes are still required' do
      actual = assert_raises I2w::DataObject::MissingAttributeError do
        FooRepo.find(id: 1)
      end
      assert_equal 'Missing attribute three', actual.message
    end

    test 'optional attributes are by Repository.with(...)' do
      repo = FooSubRepo.with(:things)
      assert_equal "I2w::RepoOptionalTest::FooSubRepo.with(:things)", repo.inspect

      actual = repo.find(id: 13)

      assert actual.success?
      assert_equal Foo, actual.value.class
      assert_equal UnloadedAttribute.new(Foo, :two), actual.value.two
      assert_equal [1, 3], actual.value.things
    end

    test 'multiple optional attributes' do
      actual = Foo2Repo.with(:stats).find(id: 123)
      assert actual.success?
      assert_equal Foo2, actual.value.class
      assert_equal({ one: 1, two: 2, three: 3, even_count: 1, odd_count: 2, count: 3 },
                   actual.value.attributes.slice(:one, :two, :three, :even_count, :odd_count, :count))
    end

    test 'specifying a scope' do
      actual = Foo2Repo.with(:posts).find(id: 123)
      assert actual.success?
      assert_equal [:post1, :post2], actual.value.posts
    end

    test 'specifying an unknwon :optional raises an error' do
      assert_raises ArgumentError do
        FooRepo.with(:unknown)
      end
    end
  end
end
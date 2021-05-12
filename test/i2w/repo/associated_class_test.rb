# frozen_string_literal: true

require 'test_helper'

module I2w
  module Repo
    class AssociatedClassTest < ActiveSupport::TestCase
      class Foo < Model; end

      class FooInput < Input; end

      class FooRecord < Record; end

      class FooRepository < Repository; end

      class StrangeFooInput < Input
        self.model_class = Foo
      end

      class StrangeFooRecord < Record
        self.model_class = Foo
      end

      test 'default associated classes' do
        assert_equal Foo, Repo.lookup(FooInput, :model)
        assert_equal Foo, Repo.lookup(FooRecord, :model)
        assert_equal Foo, Repo.lookup(FooRepository, :model)
        assert_equal FooRecord, Repo.lookup(FooRepository, :record)
        assert_equal Foo, FooRepository.model_class
        assert_equal FooRecord, FooRepository.record_class
      end

      test 'lookup associated classes' do
        assert_equal FooRepository, Repo.lookup(StrangeFooInput, :repository)
        assert_equal FooInput, Repo.lookup(StrangeFooRecord, :input)
        assert_equal FooRecord, Repo.lookup(FooRepository, :record)
        assert_equal Foo, Repo.lookup(FooRepository, :model)
      end
    end
  end
end

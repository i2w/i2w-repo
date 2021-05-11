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
        def self.model_class = Foo
      end

      class StrangeFooRecord < Record
        def self.model_class = Foo
      end

      test 'default associated classes' do
        assert_equal Foo, FooInput.model_class
        assert_equal Foo, FooRecord.model_class
        assert_equal Foo, FooRepository.model_class
        assert_equal FooRecord, FooRepository.record_class
      end

      test 'lookup associated classes' do
        assert_equal FooRepository, AssociatedClass[StrangeFooInput, :repository]
        assert_equal FooInput, AssociatedClass[StrangeFooRecord, :input]
        assert_equal FooRecord, AssociatedClass[FooRepository, :record]
        assert_equal Foo, AssociatedClass[FooRepository, :model]
      end
    end
  end
end

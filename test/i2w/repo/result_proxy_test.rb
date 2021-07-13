# frozen_string_literal: true

require 'test_helper'

module I2w
  module Repo
    class ResultProxyTest < ActiveSupport::TestCase
      class Foo < Model; end

      class FooInput < Input; end

      class FooRecord < Record; end

      class FooRepository < Repository; end

      class StrangeFooInput < Input; end

      class StrangeFooRecord < Record
        repo_base { Foo }
      end

      test 'Repo[...] returns a result proxy for the repository of the class' do
        [Foo, FooRepository, StrangeFooRecord].each do |klass|
          actual = Repo[klass]
          assert_equal ResultProxy, actual.class
          assert actual.respond_to?(:destroy)
        end
      end

      test 'Repo[...] memoizes the result' do
        foo_with_input = [Foo, FooRepository, [Foo, FooInput]].map { Repo[*_1] }
        foo_with_strange_input = [[Foo, StrangeFooInput], [FooRepository, StrangeFooInput]].map { Repo[*_1] }

        assert foo_with_input.map(&:object_id).uniq.length == 1
        assert foo_with_strange_input.map(&:object_id).uniq.length == 1
      end
    end
  end
end

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
        self.group_name = Foo
      end

      class StrangeFooRepository < Repository
        self.group_name = 'I2w::Repo::AssociatedClassTest::Foo'
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
        assert_equal FooInput, Repo.lookup(StrangeFooRepository, :input)
        assert_equal FooRecord, Repo.lookup(FooRepository, :record)
        assert_equal Foo, Repo.lookup(FooRepository, :model)
      end

      class Action
        Repo.register_class self, :action do
          def group_name = name.deconstantize.singularize

          def from_group_name(group_name, action_name)
            action_class_candidates(group_name, action_name).each do |class_name|
              return class_name.constantize
            rescue NameError
              nil
            end
            raise NameError, "can't find action, searched: #{action_class_candidates(group_name, action_name)}"
          end

          private

          def action_class_candidates(group_name, action_name)
            parts = group_name.pluralize.split('::')
            parts.length.times.map { [*parts[0..-_1], "#{action_name.to_s.camelize}Action"].join('::') }
          end
        end
      end

      class ShowAction < Action; end

      module Foos
        class EditAction < Action; end
      end

      module Backend
        class NewAction < Action; end

        class EditAction < Action; end

        module Foos
          class NewAction < Action; end
        end

        class FooRecord < Record; end

        class Controller
          Repo.register_class self do
            def group_name = name.sub(/Controller\z/, '').singularize

            def group_lookup(group_name, type, *args)
              result = Repo.lookup group_name, type, *args
              return result if result.is_a?(Class)

              Repo.lookup(group_name.sub('::Backend::', '::'), type, *args)
            end
          end
        end

        class FoosController < Controller; end
      end

      test 'lookup classes based on action lookup scheme' do
        assert_equal Foo,              Repo.lookup(Foos::EditAction, :model)
        assert_equal Foos::EditAction, Repo.lookup(Foo, :action, :edit)
        assert_equal ShowAction,       Repo.lookup(Foo, :action, :show)
      end

      test 'lookup in namespaces based on action lookup scheme' do
        assert_equal Foo,                       Repo.lookup(Backend::FoosController, :model)
        assert_equal Backend::FooRecord,        Repo.lookup(Backend::FoosController, :record)
        assert_equal FooRepository,             Repo.lookup(Backend::FoosController, :repository)
        assert_equal Backend::Foos::NewAction,  Repo.lookup(Backend::FoosController, :action, :new)
        assert_equal Backend::EditAction,       Repo.lookup(Backend::FoosController, :action, :edit)
        assert_equal ShowAction,                Repo.lookup(Backend::FoosController, :action, :show)
      end
    end
  end
end

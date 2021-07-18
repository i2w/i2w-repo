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
            "#{group_name.pluralize}::#{action_name.to_s.camelize}Action".constantize
          rescue NameError
            on_missing_action(action_name)
          end

          def on_missing_action(action_name)
            Defaults.const_get("#{action_name.to_s.camelize}Action")
          end
        end
      end

      module Defaults
        class ShowAction < Action; end
      end

      module Foos
        class EditAction < Action; end
      end

      module Backend
        class Action < AssociatedClassTest::Action
          def self.on_missing_action(action_name) = Backend.const_get("#{action_name.to_s.camelize}Action")
        end

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
              result = Repo.lookup group_name, type, *args, registry: { action: Action }
              return result if result.is_a?(Class)

              Repo.lookup(group_name.sub('::Backend::', '::'), type, *args, registry: { action: Action })
            end
          end
        end

        class FoosController < Controller; end
      end

      test 'lookup classes based on action lookup scheme' do
        assert_equal Foo,              Repo.lookup(Foos::EditAction, :model)
        assert_equal Foos::EditAction, Repo.lookup(Foo, :action, :edit)
      end

      test 'lookup with on_missing_action fallback' do
        assert_equal Defaults::ShowAction, Repo.lookup(Foo, :action, :show)
      end

      test 'lookup in namespaces based on action lookup scheme' do
        assert_equal Foo,                       Repo.lookup(Backend::FoosController, :model)
        assert_equal Backend::FooRecord,        Repo.lookup(Backend::FoosController, :record)
        assert_equal FooRepository,             Repo.lookup(Backend::FoosController, :repository)
        assert_equal Backend::Foos::NewAction,  Repo.lookup(Backend::FoosController, :action, :new)
        assert_equal Backend::EditAction,       Repo.lookup(Backend::FoosController, :action, :edit)
        
        assert_equal Group::MissingClass, Repo.lookup(Backend::FoosController, :action, :show).class
      end
    end
  end
end

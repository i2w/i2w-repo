# frozen_string_literal: true

require_relative './config'
require_relative './exceptions'

module I2w
  class Repo
    module ClassMethods
      extend Memoize

      def self.extended(repo)
        repo.singleton_class.send :private, :new # calling new on Repo is forbidden
        repo.instance_variable_set :@config, Config.new
        repo.instance_variable_set :@exceptions, Exceptions.new
      end

      delegate :transaction, :rollback!, :model, :models, :list, to: :instance

      memoize def with(*optional) = new(with: optional.compact)

      protected

      # repository dependencies must have public instance readers
      def dependency(*args, public: nil, class_only: nil) = super(*args, public: true, class_only: false)

      def exception(exception_class, handler = nil, &block) = exceptions.add(exception_class, block || handler)

      # specify an optional attribute or attributes to load
      def optional(*args, scope: NoArg, **kwargs)
        # convert :scope kwarg to a class method call if it is a symbol, then delegate to config
        kwargs[:scope] = scope.is_a?(Symbol) ? -> { send scope, _1 } : scope
        config.optional(*args, **kwargs)
      end

      # specify an optional dependent model to load
      def optional_model(name, attribute = nil, repo: nil, scope: NoArg)
        repo ||= ClassLookup.new.source(name)
                            .on_missing { "#{self.to_s.deconstantize}::#{_1.classify}Repo" }
                            .on_missing { "#{_1.classify}Repo" }

        optional_for_repo repo, :model, name, attribute, scope
      end

      # specify an optional dependent list of models to load
      def optional_list(name, attribute = nil, repo: nil, scope: NoArg)
        repo ||= ClassLookup.new.source(name)
                            .on_missing { "#{self.to_s.deconstantize}::#{_1.singularize.classify}Repo" }
                            .on_missing { "#{_1.singularize.classify}Repo" }

        optional_for_repo repo, :list, name, attribute, scope
      end

      alias optional_models optional_list

      private

      memoize def instance = new

      attr_reader :config, :exceptions

      delegate :attributes, to: :config

      def optional_for_repo(repo, meth, name, attribute = nil, scope = NoArg)
        attribute ||= lambda do |record, with|
          ClassLookup[repo].with(*with).public_send(meth, record.send(name))
        end

        scope = ->(scope, with) { scope.includes(name => with) } if scope == NoArg

        optional name, attribute, scope: scope
      end

      def inherited(subclass)
        subclass.instance_variable_set :@config, config.dup
        subclass.instance_variable_set :@exceptions, exceptions.dup
        super
      end

      def respond_to_missing?(method, ...) = instance.respond_to?(method, _include_private = false)

      def method_missing(method, ...)
        return super unless instance.respond_to?(method, _include_private = false)

        singleton_class.delegate method, to: :instance
        send(method, ...)
      end
    end
  end
end
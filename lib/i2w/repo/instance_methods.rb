# frozen_string_literal: true

module I2w
  class Repo
    module InstanceMethods
      def initialize(with: nil, **kwargs)
        super(**kwargs)
        @with              = config.assert_optional!(*with)
        @record_to_hash    = config.record_to_hash(model_class, with: @with)
        @scope             = config.scope(record_class, with: @with)
        @default_order     = config.default_order
        @rescue_as_failure = config.rescue_as_failure
        freeze
      end

      def model(record)
        model_class.new(**record_to_hash.call(record))
      end

      def list(source)
        list_class.new(source, model_class: model_class, record_to_hash: record_to_hash, default_order: default_order)
      end

      alias models list

      def transaction(&block)
        # we expect transactions to be nested, so we set sane defaults for this
        # @see https://makandracards.com/makandra/42885-nested-activerecord-transaction-pitfalls
        ActiveRecord::Base.transaction(joinable: false, requires_new: true, &block)
      end

      def rollback! = raise(ActiveRecord::Rollback)

      def to_s = "#{self.class.name}#{@with.any? ? ".with(#{@with.map(&:inspect).join(', ')})" : ''}"

      alias inspect to_s

      protected

      attr_reader :with

      # returns the active record scope for this repo, use this for finding records
      #
      # you can also set the scope for the optional block by passing a scope callable, eg.
      #
      #     def recent_posters
      #       scope -> { joins(:posts).order('posts.created_at': :desc).distinct } do
      #         all
      #       end
      #     end
      #
      # you can also pass a List object, and its scope will be used, this allows reuse of scopes
      #
      #     def all_for_user(user_id)
      #       list scope.where(user_id: user_id)
      #     end
      #
      #     def find_for_user(*args, user_id, **kwargs)
      #       scope(all_for_user(user_id)) { find(*args, **kwargs) }
      #     end
      def scope(new_scope = NoArg, &block)
        return new_scope(new_scope, &block) if new_scope != NoArg && block

        @scope
      end

      # turns a successful record_result into a model
      def model_result(...) = to_result(...).and_then { model _1 }

      # run the block, translating any Exceptions into failures, if input: kwarg is passed, and is
      # an I2w::Input, any errors will be added to that, and that is returned as the failure
      #
      # pass transaction: true to run the block inside a transaction
      #
      # Returns Result.success or Result.failure
      def to_result(obj = nil, input: nil, transaction: false, &block)
        obj = transaction ? self.transaction { rescue_as_failure(&block) } : rescue_as_failure(&block) if block
        obj = Result.to_result(obj)

        return obj if obj.success? || !input.respond_to?(:valid?)

        Result.failure(input.tap { _1.errors = obj.errors })
      end

      private

      attr_reader :record_to_hash, :default_order

      # create a temporary Repo instance with the new_scope to execute the block in
      def new_scope(new_scope, &block)
        if new_scope.is_a?(List)
          new_scope = new_scope.send(:source)
        else
          new_scope = new_scope.arity == 1 ? new_scope.call(@scope) : @scope.instance_exec(&new_scope)
        end

        new_instance = dup
        new_instance.instance_variable_set :@scope, new_scope
        new_instance.instance_exec(&block)
      end

      def config = self.class.send(:config)

      def rescue_as_failure(&block) = config.rescue_as_failure.call(&block)
    end
  end
end
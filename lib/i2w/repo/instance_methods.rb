# frozen_string_literal: true

module I2w
  class Repo
    module InstanceMethods
      def initialize(with: nil, **kwargs)
        super(**kwargs)
        @with           = config.assert_optional!(*with)
        @record_to_hash = config.record_to_hash(model_class, with: @with)
        @scope          = config.scope(record_class, with: @with)
        freeze
      end

      def model(record) = model_class.new(**record_to_hash.call(record))

      def list(source) = list_class.new(source, model_class: model_class, record_to_hash: record_to_hash)

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

      def scope(new_scope = NoArg, &block)
        return new_scope(*arg, &block) if new_scope != NoArg && block
        @scope
      end

      def scope_of_list(list, &block)
        new_scope ->(_) { list.send(:source) }, &block
      end

      def model_result(...) = record_result(...).and_then { model _1 }

      def record_result(input = nil, transaction: false, &block)
        result = if transaction
                   transaction { exceptions.wrap(&block) }
                 else
                   exceptions.wrap(&block)
                 end

        return result if result.success? || !input.respond_to?(:valid?)

        input.errors = result.errors
        Result.failure(input)
      end

      private

      attr_reader :record_to_hash

      # create a temporary Repo instance with the new_scope to execute the block in
      def new_scope(new_scope, &block)
        new_instance = dup
        new_scope = new_scope.arity == 1 ? new_scope.call(@scope) : @scope.instance_exec(&new_scope)
        new_instance.instance_variable_set :@scope, new_scope
        new_instance.instance_exec(&block)
      end

      def config = self.class.send(:config)

      def exceptions = self.class.send(:exceptions)
    end
  end
end
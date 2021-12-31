# frozen_string_literal: true

require 'i2w/result'

module I2w
  class Repo
    # handle turning ActiveRecord Exceptions into errors suitable for Result.failure
    # In situations where a repository method is called with an input: kwarg, these can be added to the input
    # A handler should return an errors hash, or string given an exception, if a handler returns a falsy value
    # superclasses will be searched.  If no handler is found, the exception will be re-raised
    #
    # use #add to add exceptions, #wrap to yield code which gets exceptions handled
    class Exceptions
      def initialize
        @exceptions = {}
      end

      def initialize_dup(source)
        @exceptions = source.exceptions.dup
      end

      def wrap
        Result.success yield
      rescue => exception
        if error = error_for_exception(exception)
          Result.failure(exception, error)
        else
          raise exception
        end
      end

      def add(exception_class, handler = nil, &block)
        exceptions[exception_class.to_s] = handler || block
      end

      protected

      attr_reader :exceptions

      private

      def error_for_exception(exception, exception_class = exception.class)
        return if exception_class == Exception # stop at Exception superclass

        if handler = exceptions[exception_class.to_s]
          error = handler.arity == 0 ? handler.call : handler.call(exception)
        end

        error || error_for_exception(exception, exception_class.superclass)
      end
    end
  end
end

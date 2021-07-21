module I2w
  class Args
    def self.call(args, result = nil, &block)
      dsl = args.is_a?(Hash) ? HashDSL.new(args, result) : ArrayDSL.new([*args], result)
      dsl.instance_eval(&block) if block
      dsl.result
    end

    class Error < RuntimeError; end

    class UnprocessedError < Error; end

    class ArrayDSL
      def initialize(args, result)
        @args = args
        @processed = []
        @result = result
      end

      def respond_to_missing?(...) = true

      def method_missing(arg)
        @result = yield(@result) if @args.include?(arg)
        @processed << arg
      end

      def missing
        @processed.concat (@args - @processed).each { @result = yield(_1, @result) }
      end

      def result
        unprocessed = @args - @processed
        raise UnprocessedError, "#{unprocessed} args were not processed" if unprocessed.any?

        @result
      end
    end

    class HashDSL
      def initialize(args, result)
        @args = args
        @processed = []
        @result = result
      end

      def respond_to_missing?(...) = true

      def method_missing(arg)
        @result = yield(@args[arg], @result) if @args.key?(arg)
        @processed << arg
      end

      def missing
        @processed.concat (@args.keys - @processed).each { @result = yield(_1, @args[_1], @result) }
      end

      def result
        unprocessed = @args.keys - @processed
        raise UnprocessedError, "#{unprocessed} args were not processed" if unprocessed.any?

        @result
      end
    end
  end
end
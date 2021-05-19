module I2w
  class Input < DataObject::Mutable
    class WithModel
      attr_reader :input, :model

      def initialize(input, model)
        @input = input
        @model = model
      end

      delegate :errors, :to_input, to: :input
    end
  end
end

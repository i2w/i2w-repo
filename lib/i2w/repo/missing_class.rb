# frozen_string_literal: true

require 'active_support/all'

module I2w
  module Repo
    # represents a repo class that couldn't be found.
    class MissingClass
      def initialize(name, type: nil, error: nil, message: nil)
        @name = name
        @type = type
        @error = error
        @message = message
      end
    end
  end
end

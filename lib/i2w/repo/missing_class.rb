# frozen_string_literal: true

require 'active_support/all'

module I2w
  module Repo
    # represents a repo class that couldn't be found.
    class MissingClass
      attr_reader :name, :type, :message, :exception

      def initialize(exception = nil, type: nil, name: nil, message: nil)
        @type = type
        @exception = exception
        @name = name || exception&.missing_name
        @message = message || exception&.message
      end

      def to_s = "MissingClass[#{name}]"
    end
  end
end

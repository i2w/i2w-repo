# frozen_string_literal: true

require 'active_support/core_ext/object/instance_variables'
require 'active_model'
require 'i2w/data_object'
require 'i2w/input/base'

module I2w
  module Input
    class Error < RuntimeError; end

    class InvalidAttributesError < Error; end

    class ValidationContextUnsupportedError < Error; end
  end
end



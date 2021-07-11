# frozen_string_literal: true

require 'i2w/memoize'

require_relative 'repo/version'
require_relative 'input'
require_relative 'model'
require_relative 'record'
require_relative 'repository'
require_relative 'repo/result_proxy'
require_relative 'repo/lookup_class'

module I2w
  # Repo contains a bunch of loosely coupled classes for implementing a repository pattern, with optional
  # monadic results, on top of active record.
  module Repo
    class << self
      extend Memoize

      memoize def for(klass, input_class = nil)
        repository_class = lookup(klass, :repository)
        input_class ||= lookup(repository_class, :input)
        input_class = Input if input_class.is_a?(MissingClass)

        result_proxy(repository_class, input_class)
      end

      alias [] for

      memoize def result_proxy(...) = ResultProxy.new(...)

      memoize def lookup(klass, type) = LookupClass.call(klass, type)
    end

    class Error < RuntimeError; end

    class NotRepoClassError < Error
      def initialize(message = 'class must respond to #repo_class_type or #model_class', *args, **opts)
        super(message, *args, **opts)
      end
    end
  end
end

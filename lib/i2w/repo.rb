# frozen_string_literal: true

require 'i2w/memoize'

require_relative 'repo/version'
require_relative 'group'
require_relative 'repo/result_proxy'

module I2w
  # Repo contains a bunch of loosely coupled classes for implementing a repository pattern, with optional
  # monadic results, on top of active record.
  module Repo
    class << self
      extend Memoize

      memoize def result_proxy(klass, input_class = nil)
        repository_class = group.lookup(klass, :repository)
        input_class ||= group.lookup(repository_class, :input)

        # TODO: make a special class for ResultInput or something
        input_class = Input if input_class.is_a?(Group::MissingClass)

        new_result_proxy(repository_class, input_class)
      end

      alias [] result_proxy

      attr_reader :group

      memoize def lookup(...) = group.lookup(...)

      memoize def new_result_proxy(repository_class, input_class) = repository_class::ResultProxy.new(repository_class, input_class)

      def register_class(...) = group.register(...)
    end

    @group = Group.new
  end
end

require_relative 'input'
require_relative 'model'
require_relative 'record'
require_relative 'repository'

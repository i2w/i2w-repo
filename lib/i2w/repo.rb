# frozen_string_literal: true

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
      def result_proxy(klass, input_class = nil)
        repository_class = lookup(klass, :repository)
        input_class ||= lookup(repository_class, :input)

        @result_proxies ||= Hash.new { |m, args| m[args] = ResultProxy.new(*args) }
        @result_proxies[[repository_class, input_class]]
      end
      alias [] result_proxy

      def lookup(klass, type)
        @lookups ||= Hash.new { |m, args| m[args] = LookupClass.call(*args) }
        @lookups[[klass, type]]
      end
    end
  end
end

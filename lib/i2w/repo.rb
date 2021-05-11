# frozen_string_literal: true

require_relative 'repo/version'
require_relative 'repo/associated_class'
require_relative 'repo/result_proxy'

module I2w
  # Repo contains a bunch of loosely coupled classes for implementing a repository pattern, with optional
  # monadic results, on top of active record.
  module Repo
    class << self
      def result_proxy(repository_class, input_class = nil)
        @result_proxies ||= Hash.new { |m, args| m[args] = ResultProxy.new(*args) }
        @result_proxies[[repository_class, input_class]]
      end
      alias [] result_proxy

      def associated_class_extension(...)
        AssociatedClass::Extension.new(...)
      end
    end
  end
end

require_relative 'input'
require_relative 'model'
require_relative 'record'
require_relative 'repository'

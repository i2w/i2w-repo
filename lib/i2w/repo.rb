# frozen_string_literal: true

require 'i2w/memoize'

require_relative 'repo/version'
require_relative 'input'
require_relative 'model'
require_relative 'record'
require_relative 'repository'
require_relative 'repo/result_proxy'
require_relative 'repo/class'

module I2w
  # Repo contains a bunch of loosely coupled classes for implementing a repository pattern, with optional
  # monadic results, on top of active record.
  module Repo
    class << self
      extend Memoize

      memoize def for(klass, input_class = nil)
        repository_class = Repo::Class.lookup(klass, :repository)
        input_class ||= Repo::Class.lookup(repository_class, :input)

        # TODO: make a special class for ResultInput or something
        input_class = Input if input_class.is_a?(Repo::Class::Ref)

        result_proxy(repository_class, input_class)
      end

      alias [] for

      memoize def result_proxy(...) = ResultProxy.new(...)

      memoize def lookup(...) = Repo::Class.lookup(...)
    end
  end
end

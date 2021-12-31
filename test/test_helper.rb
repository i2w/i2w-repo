# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require 'active_support'
require 'ruby_jard'

require 'i2w/repo'

begin
  ActiveRecord::Base.establish_connection adapter: "postgresql", database: "i2w-repo_test"
  require_relative 'schema'

rescue ActiveRecord::NoDatabaseError
  puts <<~EOD
    Please create a postgresql database for testing this gem.  Do so by running the following:

    createdb i2w-repo_test

  EOD
  exit 1
end


require_relative 'records'

class ActiveSupport::TestCase
  # specify this to truncate all data in tables after your test creates data
  def self.truncate_tables
    teardown do
      ActiveRecord::Base.connection.truncate_tables(*ActiveRecord::Base.connection.tables)
    end
  end
end

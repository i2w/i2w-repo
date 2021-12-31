source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in i2w-repo.gemspec.
gemspec

group :development do
  gem 'pg'
  gem 'minitest-autotest'

  # TODO: once below are gems, move them to the gemspec
  gem 'i2w-data_object', github: 'i2w/i2w-data_object', branch: 'main'
  gem 'i2w-result', github: 'i2w/i2w-result', branch: 'main'
end

# To use a debugger
gem 'ruby_jard', groups: ['development', 'test']

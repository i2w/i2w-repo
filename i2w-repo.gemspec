require_relative 'lib/i2w/repo/version'

Gem::Specification.new do |s|
  s.name        = 'i2w-repo'
  s.version     = I2w::Repo::VERSION

  s.required_ruby_version = '>= 3.0.0'

  s.authors     = ['Ian White']
  s.email       = ['ian.w.white@gmail.com']
  # spec.homepage    = "TODO"
  s.summary     = 'Summary of I2w::Repo.'
  s.description = 'Description of I2w::Repo.'
  # spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  #
  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  #
  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_development_dependency 'activerecord', '>= 6'
  s.add_development_dependency 'rake', '>= 13.0.3'
end

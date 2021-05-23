require_relative "lib/planter/version"

Gem::Specification.new do |spec|
  spec.name        = "planter"
  spec.version     = Planter::VERSION
  spec.authors     = ["Evan Gray"]
  spec.email       = ["evanthegrayt@vivaldi.net"]
  spec.homepage    = "https://github.com/evanthegrayt/planter"
  spec.summary     = "Framework for seeding rails applications."
  spec.description = "Create a seeder for each table in your database, and easily seed from CSV or custom methods"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata['documentation_uri'] =
    'https://evanthegrayt.github.io/standup_md/'

  spec.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  spec.add_dependency "rails", "~> 6.1.3", ">= 6.1.3.1"
end

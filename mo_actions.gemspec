require_relative "lib/mo_actions/version"

Gem::Specification.new do |spec|
  spec.name        = "mo_actions"
  spec.version     = MoActions::VERSION
  spec.authors     = [ "Adam Akhtar" ]
  spec.email       = [ "adamsubscribe@googlemail.com" ]
  spec.homepage    = "https://github.com/adamakhtar/mo_actions"
  spec.summary     = "A Rails engine for defining, running, and observing operational actions."
  spec.description = "Mo Actions lets developers define operational actions in Ruby and gives operators a dashboard to discover and run them."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "rails", ">= 7.0"
end

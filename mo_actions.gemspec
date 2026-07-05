require_relative "lib/mo_actions/version"

Gem::Specification.new do |spec|
  spec.name = "mo_actions"
  spec.version = MoActions::VERSION
  spec.authors = ["Mo Actions contributors"]
  spec.email = ["support@example.com"]

  spec.summary = "Mountable Rails dashboard for operational actions."
  spec.description = "Mo Actions lets Rails applications expose authenticated operational actions through a bundled dashboard."
  spec.homepage = "https://example.com/mo_actions"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,config,lib}/**/*", "MIT-LICENSE", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "stimulus-rails"
  spec.add_dependency "turbo-rails"

  spec.add_development_dependency "sqlite3"
end

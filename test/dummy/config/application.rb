require_relative "boot"

require "rails/all"
require "mo_actions"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults 7.0

    config.eager_load = false
    config.root = File.expand_path("..", __dir__)
  end
end

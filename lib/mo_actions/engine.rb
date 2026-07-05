require "rails"
require "turbo-rails"
require "stimulus-rails"

module MoActions
  class Engine < ::Rails::Engine
    isolate_namespace MoActions

    config.to_prepare do
      MoActions::Registry.reset!

      actions_path = Rails.application.root.join("app/actions")
      Dir[actions_path.join("**/*_action.rb")].sort.each { |file| load file }
    end
  end
end

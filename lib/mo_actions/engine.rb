module MoActions
  class Engine < ::Rails::Engine
    isolate_namespace MoActions

    # Host actions live in app/actions and are registered via
    # MoActions::Base.inherited. Zeitwerk autoloading is lazy, so we eager
    # load that directory on boot and after every code reload. Reloading
    # unloads the old action classes, so the registry is rebuilt from
    # scratch each time.
    config.to_prepare do
      MoActions::Registry.reset!
      actions_dir = Rails.root.join("app/actions")
      Rails.autoloaders.main.eager_load_dir(actions_dir) if actions_dir.exist?
    end
  end
end

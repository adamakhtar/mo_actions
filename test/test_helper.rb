# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../test/dummy/db/migrate", __dir__) ]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

class ActiveSupport::TestCase
  setup do
    # Drop the dummy initializer's config so each test starts from defaults
    # (or its own explicit configure block).
    MoActions.reset_config!
  end
end

class ActionDispatch::IntegrationTest
  def authenticate_as(performer)
    MoActions.configure do |config|
      config.current_performer = ->(_controller) { performer }
      config.authenticate_with = ->(controller) do
        controller.head :forbidden unless controller.current_performer
      end
    end
  end
end

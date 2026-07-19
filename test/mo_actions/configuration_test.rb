require "test_helper"

module MoActions
  class ConfigurationTest < ActiveSupport::TestCase
    test "defaults leave auth hooks unset" do
      assert_nil MoActions.config.authenticate_with
      assert_nil MoActions.config.current_performer
    end

    test "configure sets authentication and performer hooks" do
      authenticate = ->(controller) { controller.head :forbidden }
      performer = ->(_controller) { User.new(name: "Ada") }

      MoActions.configure do |config|
        config.authenticate_with = authenticate
        config.current_performer = performer
      end

      assert_same authenticate, MoActions.config.authenticate_with
      assert_same performer, MoActions.config.current_performer
    end

    test "reset_config! restores defaults" do
      MoActions.configure do |config|
        config.authenticate_with = ->(_controller) { true }
      end

      MoActions.reset_config!

      assert_nil MoActions.config.authenticate_with
      assert_nil MoActions.config.current_performer
    end
  end
end

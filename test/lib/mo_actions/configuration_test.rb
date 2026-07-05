require_relative "../../test_helper"

module MoActions
  class ConfigurationTest < ActiveSupport::TestCase
    test "defaults to the host User performer class name" do
      assert_equal "User", MoActions.config.performer_class_name
      assert_equal User, MoActions.config.performer_class
      assert_nil MoActions.config.authenticate_with
      assert_nil MoActions.config.current_performer
    end

    test "configure exposes authentication and performer hooks" do
      authenticate = ->(controller) { controller.head :forbidden }
      performer = ->(_controller) { User.new(name: "Ada") }

      MoActions.configure do |config|
        config.performer_class_name = "Admin"
        config.authenticate_with = authenticate
        config.current_performer = performer
      end

      assert_equal "Admin", MoActions.config.performer_class_name
      assert_same authenticate, MoActions.config.authenticate_with
      assert_same performer, MoActions.config.current_performer
    end
  end
end

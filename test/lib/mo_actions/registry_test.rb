require_relative "../../test_helper"

module MoActions
  class RegistryTest < ActiveSupport::TestCase
    teardown do
      remove_test_constants
      rediscover_dummy_actions
    end

    test "defining a categorized subclass registers it" do
      action = define_action(:ArchiveRecordsAction, category: :maintenance)

      assert_equal action, Registry.find("archive_records")
      assert_equal "Archive records", action.name
    end

    test "keys can be overridden" do
      action = define_action(:ExportRecordsAction, key: "custom_export", category: :maintenance)

      assert_equal action, Registry.find("custom_export")
      assert_raises(ActionNotFound) { Registry.find("export_records") }
    end

    test "duplicate keys raise with both class names" do
      define_action(:FirstDuplicateAction, key: "duplicate", category: :billing)

      error = assert_raises(Registry::DuplicateKey) do
        define_action(:SecondDuplicateAction, key: "duplicate", category: :maintenance)
      end

      assert_includes error.message, "FirstDuplicateAction"
      assert_includes error.message, "SecondDuplicateAction"
      assert_includes error.message, "duplicate"
    end

    test "missing category raises with an actionable message" do
      action = Class.new(Base)
      Object.const_set(:UncategorizedAction, action)

      error = assert_raises(Registry::MissingCategory) { Registry.register(action) }

      assert_includes error.message, "UncategorizedAction"
      assert_includes error.message, "category :maintenance"
    end

    test "actions are grouped by category and ordered by name" do
      define_action(:ZuluBillingAction, name: "Zulu Billing", category: :billing)
      define_action(:AlphaBillingAction, name: "Alpha Billing", category: :billing)
      define_action(:MaintenanceTaskAction, name: "Maintenance Task", category: :maintenance)

      grouped = Registry.by_category

      assert_equal [:billing, :maintenance], grouped.keys
      assert_equal ["Alpha Billing", "Zulu Billing"], grouped[:billing].map(&:name)
      assert_equal ["Maintenance Task"], grouped[:maintenance].map(&:name)
    end

    test "dummy action discovery can rebuild the registry after reset" do
      Registry.reset!

      rediscover_dummy_actions

      assert_equal ImportUsersAction, Registry.find("import_users")
      assert_equal SendInvoiceRemindersAction, Registry.find("send_invoice_reminders")
      assert_equal PurgeStaleSessionsAction, Registry.find("purge_stale_sessions")
    end

    private

    def define_action(constant_name, key: nil, name: nil, category:)
      action = Class.new(Base)
      Object.const_set(constant_name, action)
      action.key(key) if key
      action.name(name) if name
      action.description("#{constant_name} description")
      action.category(category)
      action
    end

    def remove_test_constants
      %i[
        ArchiveRecordsAction
        ExportRecordsAction
        FirstDuplicateAction
        SecondDuplicateAction
        UncategorizedAction
        ZuluBillingAction
        AlphaBillingAction
        MaintenanceTaskAction
      ].each do |constant_name|
        Object.remove_const(constant_name) if Object.const_defined?(constant_name, false)
      end
    end
  end
end

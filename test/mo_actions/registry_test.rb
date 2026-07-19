require "test_helper"

class MoActions::RegistryTest < ActiveSupport::TestCase
  test "defining a subclass registers it" do
    assert_includes MoActions::Registry.all, SendInvoiceRemindersAction
    assert_includes MoActions::Registry.all, PurgeStaleSessionsAction
  end

  test "find returns the action for a key" do
    assert_equal SendInvoiceRemindersAction, MoActions::Registry.find("send_invoice_reminders")
  end

  test "find raises for an unknown key" do
    error = assert_raises(MoActions::ActionNotFound) { MoActions::Registry.find("nope") }
    assert_match(/"nope"/, error.message)
  end

  test "by_category groups actions by their category" do
    by_category = MoActions::Registry.by_category

    assert_includes by_category[:billing], SendInvoiceRemindersAction
    assert_includes by_category[:maintenance], PurgeStaleSessionsAction
    assert_equal by_category.keys.sort_by(&:to_s), by_category.keys
  end

  test "registry can be reset and rebuilt, as happens on code reload" do
    original = MoActions::Registry.all

    MoActions::Registry.reset!
    assert_empty MoActions::Registry.all

    original.each { |action| MoActions::Registry.register(action) }
    assert_equal SendInvoiceRemindersAction, MoActions::Registry.find("send_invoice_reminders")
  end
end

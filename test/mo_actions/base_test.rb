require "test_helper"

class BareTestAction < MoActions::Base
  category :testing
end

class CustomKeyTestAction < MoActions::Base
  key "custom_key"
  category :testing
end

class MoActions::BaseTest < ActiveSupport::TestCase
  test "key is derived from the class name" do
    assert_equal "send_invoice_reminders", SendInvoiceRemindersAction.key
  end

  test "key can be overridden" do
    assert_equal "custom_key", CustomKeyTestAction.key
  end

  test "display_name and description come from the DSL" do
    assert_equal "Send Invoice Reminders", SendInvoiceRemindersAction.display_name
    assert_match(/overdue invoice/, SendInvoiceRemindersAction.description)
  end

  test "display_name defaults to the humanized key" do
    assert_equal "Bare test", BareTestAction.display_name
  end

  test "category comes from the DSL" do
    assert_equal :billing, SendInvoiceRemindersAction.category
    assert_equal :maintenance, PurgeStaleSessionsAction.category
  end

  test "reading a missing category raises with an actionable message" do
    with_isolated_registry do
      klass = Class.new(MoActions::Base) do
        def self.name = "NoCategoryAction"
      end

      error = assert_raises(MoActions::MissingCategory) { klass.category }
      assert_match(/NoCategoryAction has no category/, error.message)
      assert_match(/category :some_category/, error.message)
    end
  end

  test "perform must be implemented by subclasses" do
    assert_raises(NotImplementedError) { BareTestAction.new.perform }
  end

  private

  def with_isolated_registry
    original = MoActions::Registry.all
    yield
  ensure
    MoActions::Registry.reset!
    original.each { |action| MoActions::Registry.register(action) }
  end
end

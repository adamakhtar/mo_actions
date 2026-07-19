require "test_helper"

class ReminderArgsTestAction < MoActions::Base
  category :testing

  argument :email, type: :string, required: true, description: "Who to notify"
  argument :limit, type: :integer
  argument :dry_run, type: :boolean
end

module MoActions
  class ArgumentDslTest < ActiveSupport::TestCase
    test "argument declarations are retained in order" do
      definitions = ReminderArgsTestAction.arguments

      assert_equal %i[email limit dry_run], definitions.map(&:name)
      assert_equal :string, definitions.first.type
      assert_equal "Who to notify", definitions.first.description
      assert definitions.first.required?
      assert_not definitions[1].required?
    end

    test "initialize keeps raw params until cast_arguments!" do
      action = ReminderArgsTestAction.new(
        "email" => "ops@example.com",
        "limit" => "10",
        "dry_run" => "1"
      )

      assert_equal "ops@example.com", action.email
      assert_equal "10", action.limit
      assert_equal "1", action.dry_run

      action.cast_arguments!

      assert_equal "ops@example.com", action.email
      assert_equal 10, action.limit
      assert_equal true, action.dry_run
    end

    test "argument_values returns values after cast" do
      action = ReminderArgsTestAction.new(
        email: "ops@example.com",
        limit: "10",
        dry_run: "0"
      ).cast_arguments!

      assert_equal(
        { "email" => "ops@example.com", "limit" => 10, "dry_run" => false },
        action.argument_values
      )
    end

    test "required blank fails validation before cast" do
      action = ReminderArgsTestAction.new(email: "", limit: "5")

      assert_not action.valid?
      assert_includes action.errors[:email], "can't be blank"
      assert_equal "", action.email
      assert_equal "5", action.limit
    end

    test "non-integer fails validation before cast would coerce to 0" do
      action = ReminderArgsTestAction.new(email: "ops@example.com", limit: "abc")

      assert_not action.valid?
      assert action.errors[:limit].any?
      assert_equal "abc", action.limit
    end

    test "valid raw input passes and can be cast" do
      action = ReminderArgsTestAction.new(email: "ops@example.com", limit: "5", dry_run: "1")

      assert action.valid?
      action.cast_arguments!
      assert_equal 5, action.limit
      assert_equal true, action.dry_run
    end

    test "optional integer may be blank" do
      action = ReminderArgsTestAction.new(email: "ops@example.com", limit: "")

      assert action.valid?
      action.cast_arguments!
      assert_nil action.limit
    end

    test "redeclaring an argument replaces the previous definition" do
      with_isolated_registry do
        klass = Class.new(MoActions::Base) do
          def self.name = "ReplaceArgAction"
          category :testing
          argument :count, type: :string
          argument :count, type: :integer, required: true, description: "How many"
        end

        assert_equal 1, klass.arguments.size
        assert_equal :integer, klass.arguments.first.type
        assert_equal "How many", klass.arguments.first.description
        assert klass.arguments.first.required?

        action = klass.new(count: "abc")
        assert_not action.valid?
        assert action.errors[:count].any?
      end
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
end

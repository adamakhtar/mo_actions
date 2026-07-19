require "test_helper"

class ReminderArgsTestAction < MoActions::Base
  category :testing

  argument :email, type: :string, description: "Who to notify"
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
    end

    test "initialize coerces params onto instance readers" do
      action = ReminderArgsTestAction.new(
        "email" => "ops@example.com",
        "limit" => "10",
        "dry_run" => "1"
      )

      assert_equal "ops@example.com", action.email
      assert_equal 10, action.limit
      assert_equal true, action.dry_run
    end

    test "argument_values returns coerced values keyed by name" do
      action = ReminderArgsTestAction.new(
        email: "ops@example.com",
        limit: "10",
        dry_run: "0"
      )

      assert_equal(
        { "email" => "ops@example.com", "limit" => 10, "dry_run" => false },
        action.argument_values
      )
    end

    test "redeclaring an argument replaces the previous definition" do
      with_isolated_registry do
        klass = Class.new(MoActions::Base) do
          def self.name = "ReplaceArgAction"
          category :testing
          argument :count, type: :string
          argument :count, type: :integer, description: "How many"
        end

        assert_equal 1, klass.arguments.size
        assert_equal :integer, klass.arguments.first.type
        assert_equal "How many", klass.arguments.first.description
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

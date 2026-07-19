require "test_helper"

class ReminderArgsTestAction < MoActions::Base
  category :testing

  argument :email, type: :string, description: "Who to notify"
  argument :limit, type: :integer
  argument :dry_run, type: :boolean

  def perform(_ctx); end
end

module MoActions
  class ArgumentDslTest < ActiveSupport::TestCase
    test "argument declarations are retained in order" do
      definitions = ReminderArgsTestAction.arguments

      assert_equal %i[email limit dry_run], definitions.map(&:name)
      assert_equal :string, definitions.first.type
      assert_equal "Who to notify", definitions.first.description
    end

    test "initialize keeps raw params until execute casts them" do
      action = ReminderArgsTestAction.new(
        "email" => "ops@example.com",
        "limit" => "10",
        "dry_run" => "1"
      )

      assert_equal "ops@example.com", action.email
      assert_equal "10", action.limit
      assert_equal "1", action.dry_run

      assert_difference -> { MoActions::Execution.count }, 1 do
        assert action.execute
      end

      assert_equal "ops@example.com", action.email
      assert_equal 10, action.limit
      assert_equal true, action.dry_run
      assert action.execution.succeeded?
    end

    test "execute returns false when invalid and does not cast, perform, or persist" do
      klass = Class.new(MoActions::Base) do
        def self.name = "ExecuteGuardAction"
        category :testing
        argument :label, type: :string, required: true

        def perform(_ctx)
          raise "perform should not run"
        end
      end

      action = klass.new(label: "")
      assert_no_difference -> { MoActions::Execution.count } do
        assert_not action.execute
      end
      assert_equal "", action.label
      assert_nil action.execution
      assert_includes action.errors[:label], "can't be blank"
    end

    test "execute casts arguments, enqueues work, and records a succeeded execution" do
      user = User.create!(name: "Ada")
      action = ReminderArgsTestAction.new(
        email: "ops@example.com",
        limit: "10",
        dry_run: "0"
      )

      assert action.execute(performer: user)
      assert_equal(
        { "email" => "ops@example.com", "limit" => 10, "dry_run" => false },
        action.argument_values
      )
      assert_equal "succeeded", action.execution.reload.status
      assert_equal user, action.execution.performer
      assert_equal "reminder_args_test", action.execution.action_key
    end

    test "execute records a failed execution when perform raises" do
      klass = Class.new(MoActions::Base) do
        def self.name = "BoomAction"
        category :testing

        def perform(_ctx)
          raise "boom"
        end
      end

      action = klass.new
      assert action.execute
      assert action.execution.reload.failed?
      assert_equal "boom", action.execution.error_message
    end

    test "perform can report total and progress onto the execution" do
      klass = Class.new(MoActions::Base) do
        def self.name = "ProgressAction"
        category :testing

        def perform(ctx)
          ctx.total = 4
          ctx.progress(2)
        end
      end

      action = klass.new
      assert action.execute
      execution = action.execution.reload
      assert execution.succeeded?
      assert_equal 4, execution.progress_total
      assert_equal 2, execution.progress_current
    end

    test "required arguments use ActiveModel presence validation" do
      klass = Class.new(MoActions::Base) do
        def self.name = "RequiredArgAction"
        category :testing
        argument :label, type: :string, required: true
        def perform(_ctx); end
      end

      action = klass.new(label: "")
      assert_not action.valid?
      assert_includes action.errors[:label], "can't be blank"
    end

    test "integer arguments use ActiveModel numericality validation on raw input" do
      action = ReminderArgsTestAction.new(limit: "abc")
      assert_not action.valid?
      assert_includes action.errors[:limit], "is not a number"

      action = ReminderArgsTestAction.new(limit: "10")
      assert action.valid?
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

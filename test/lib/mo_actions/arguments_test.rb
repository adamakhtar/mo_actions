require_relative "../../test_helper"

module MoActions
  class ArgumentsTest < ActiveSupport::TestCase
    test "dummy import action exposes ordered argument definitions" do
      definitions = ImportUsersAction.argument_definitions

      assert_equal [:source, :batch_size, :notify, :started_on, :run_at, :discount_rate, :user_ids, :mapping_file], definitions.map(&:name)
      assert_equal "Where to pull users from", definitions.first.description
      assert_predicate definitions.first, :default?
      assert_not definitions.first.required?
    end

    test "defaults apply and typed values are exposed by reader and index" do
      args = Arguments.build(ImportUsersAction, "user_ids" => ["1", "2"])

      assert_predicate args, :valid?
      assert_equal "csv", args.source
      assert_equal 100, args[:batch_size]
      assert_equal false, args.notify
      assert_equal [1, 2], args.user_ids
    end

    test "casts all scalar types" do
      args = Arguments.build(ImportUsersAction, {
        source: "api",
        batch_size: "10",
        notify: "1",
        started_on: "2026-07-05",
        run_at: "2026-07-05 12:30:00 UTC",
        discount_rate: "1.25",
        user_ids: ["42"],
        mapping_file: "signed-file-id"
      })

      assert_predicate args, :valid?
      assert_equal "api", args.source
      assert_equal 10, args.batch_size
      assert_equal true, args.notify
      assert_equal Date.new(2026, 7, 5), args.started_on
      assert_equal BigDecimal("1.25"), args.discount_rate
      assert_equal "signed-file-id", args.mapping_file
      assert_equal 12, args.run_at.hour
    end

    test "uncastable input records field errors" do
      args = Arguments.build(ImportUsersAction, {
        source: "ftp",
        batch_size: "abc",
        notify: "maybe",
        started_on: "not-a-date",
        run_at: "not-a-time",
        discount_rate: "abc",
        user_ids: ["1"]
      })

      assert_not args.valid?
      assert_includes args.errors[:source], "is not included in csv, api"
      assert_includes args.errors[:batch_size], "is not an integer"
      assert_includes args.errors[:started_on], "is not a date"
      assert_includes args.errors[:run_at], "is not a datetime"
      assert_includes args.errors[:discount_rate], "is not a decimal"
    end

    test "boolean handles expected form values and blank nil" do
      assert_equal true, argument_value(:boolean, "1")
      assert_equal true, argument_value(:boolean, "true")
      assert_equal false, argument_value(:boolean, "0")
      assert_equal false, argument_value(:boolean, "false")
      assert_equal true, argument_value(:boolean, "maybe")
      assert_nil argument_value(:boolean, "")
      assert_nil argument_value(:boolean, nil)
    end

    test "required optional and default interaction" do
      args = Arguments.build(ImportUsersAction, {})

      assert_not args.valid?
      assert_includes args.errors[:user_ids], "can't be blank"
      assert_equal 100, args.batch_size
      assert_nil args.started_on
    end

    test "arrays cast elements and report indexed errors" do
      args = Arguments.build(ImportUsersAction, user_ids: ["1", "abc", "3"])

      assert_not args.valid?
      assert_equal [1, nil, 3], args.user_ids
      assert_includes args.errors[:"user_ids[1]"], "is not an integer"
    end

    test "array validations enforce min max and uniqueness" do
      missing = Arguments.build(ImportUsersAction, user_ids: [])
      duplicate = Arguments.build(ImportUsersAction, user_ids: ["1", "1"])
      too_many = Arguments.build(small_array_action, numbers: ["1", "2", "3"])

      assert_includes missing.errors[:user_ids], "must have at least 1 item(s)"
      assert_includes duplicate.errors[:user_ids], "must contain unique values"
      assert_includes too_many.errors[:numbers], "must have at most 2 item(s)"
    end

    test "element validations apply to each array item" do
      action = Class.new(Base) do
        argument :scores, :integer, array: true, validates: { numericality: { greater_than: 0 } }
      end

      args = Arguments.build(action, scores: ["1", "0", "-1"])

      assert_includes args.errors[:"scores[1]"], "must be greater than 0"
      assert_includes args.errors[:"scores[2]"], "must be greater than 0"
    end

    test "custom validation lambdas and methods are supported" do
      action = Class.new(Base) do
        argument :slug, :string, validates: { custom: ->(value) { "must be lowercase" unless value == value.downcase } }
        argument :code, :string, validates: { validate: :valid_code }

        def self.valid_code(value)
          value.start_with?("ok-") || "must start with ok-"
        end
      end

      args = Arguments.build(action, slug: "Bad", code: "nope")

      assert_includes args.errors[:slug], "must be lowercase"
      assert_includes args.errors[:code], "must start with ok-"
    end

    test "to_h is json serializable" do
      args = Arguments.build(ImportUsersAction, {
        source: "api",
        batch_size: "10",
        notify: "0",
        started_on: "2026-07-05",
        run_at: "2026-07-05 12:30:00 UTC",
        discount_rate: "1.25",
        user_ids: ["1", "2"],
        mapping_file: "signed-file-id"
      })

      round_tripped = JSON.parse(JSON.generate(args.to_h))

      assert_equal "api", round_tripped["source"]
      assert_equal "1.25", round_tripped["discount_rate"]
      assert_equal "2026-07-05", round_tripped["started_on"]
      assert_equal [1, 2], round_tripped["user_ids"]
    end

    private

    def argument_value(type, raw)
      action = Class.new(Base) { argument :value, type, required: false }
      Arguments.build(action, value: raw).value
    end

    def small_array_action
      Class.new(Base) do
        argument :numbers, :integer, array: true, array_validates: { max_items: 2 }
      end
    end
  end
end

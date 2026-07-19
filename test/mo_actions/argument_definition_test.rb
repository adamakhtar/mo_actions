require "test_helper"

module MoActions
  class ArgumentDefinitionTest < ActiveSupport::TestCase
    test "casts string, integer, and boolean values" do
      string = ArgumentDefinition.new(name: :label, type: :string)
      integer = ArgumentDefinition.new(name: :count, type: :integer)
      boolean = ArgumentDefinition.new(name: :notify, type: :boolean)

      assert_equal "hello", string.cast("hello")
      assert_equal 42, integer.cast("42")
      assert_equal true, boolean.cast("1")
      assert_equal false, boolean.cast("0")
    end

    test "integer casting follows ActiveModel::Type::Integer" do
      integer = ArgumentDefinition.new(name: :count, type: :integer)

      assert_nil integer.cast(nil)
      assert_nil integer.cast("")
      # Rails' integer type uses to_i, so non-numeric strings become 0.
      # Validation rejects these before cast — see ArgumentDslTest.
      assert_equal 0, integer.cast("abc")
    end

    test "required defaults to false and can be enabled" do
      optional = ArgumentDefinition.new(name: :label, type: :string)
      required = ArgumentDefinition.new(name: :label, type: :string, required: true)

      assert_not optional.required?
      assert required.required?
    end

    test "rejects unsupported types" do
      error = assert_raises(ArgumentError) do
        ArgumentDefinition.new(name: :when, type: :date)
      end

      assert_match(/unsupported argument type :date/, error.message)
    end
  end
end

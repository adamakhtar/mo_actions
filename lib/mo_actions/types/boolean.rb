module MoActions
  module Types
    class Boolean
      TRUE_VALUES = [true, 1, "1", "true", "TRUE"].freeze
      FALSE_VALUES = [false, 0, "0", "false", "FALSE"].freeze

      def initialize(**)
      end

      def cast(raw)
        return Result.new(value: nil) if raw.nil? || raw == ""
        return Result.new(value: true) if TRUE_VALUES.include?(raw)
        return Result.new(value: false) if FALSE_VALUES.include?(raw)

        Result.new(error: "is not a boolean")
      end
    end
  end
end

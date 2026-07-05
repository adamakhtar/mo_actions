module MoActions
  module Types
    class Decimal
      def initialize(**)
      end

      def cast(raw)
        return Result.new(value: nil) if raw.nil? || raw == ""

        Result.new(value: BigDecimal(raw.to_s))
      rescue ArgumentError
        Result.new(error: "is not a decimal")
      end
    end
  end
end

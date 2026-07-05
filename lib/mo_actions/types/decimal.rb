module MoActions
  module Types
    class Decimal
      def initialize(**)
        @type = ActiveModel::Type::Decimal.new
      end

      def cast(raw)
        return Result.new(value: nil) if raw.nil? || raw == ""
        return Result.new(error: "is not a decimal") unless decimal_like?(raw)

        Result.new(value: @type.cast(raw))
      end

      private

      def decimal_like?(raw)
        raw.is_a?(Numeric) || BigDecimal(raw.to_s, exception: false).present?
      end
    end
  end
end

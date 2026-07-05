module MoActions
  module Types
    class Integer
      def initialize(**)
        @type = ActiveModel::Type::Integer.new
      end

      def cast(raw)
        return Result.new(value: nil) if raw.nil? || raw == ""
        return Result.new(error: "is not an integer") unless integer_like?(raw)

        Result.new(value: @type.cast(raw))
      end

      private

      def integer_like?(raw)
        raw.is_a?(Numeric) || raw.to_s.match?(/\A[+-]?\d+\z/)
      end
    end
  end
end

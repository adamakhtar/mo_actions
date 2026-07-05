module MoActions
  module Types
    class Enum
      attr_reader :values

      def initialize(values:, **)
        @values = values.map(&:to_s)
      end

      def cast(raw)
        return Result.new(value: nil) if raw.nil? || raw == ""

        value = raw.to_s
        values.include?(value) ? Result.new(value: value) : Result.new(error: "is not included in #{values.join(', ')}")
      end
    end
  end
end

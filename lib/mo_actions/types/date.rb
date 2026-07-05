module MoActions
  module Types
    class Date
      def initialize(**)
        @type = ActiveModel::Type::Date.new
      end

      def cast(raw)
        return Result.new(value: nil) if raw.nil? || raw == ""

        value = @type.cast(raw)
        value ? Result.new(value: value) : Result.new(error: "is not a date")
      end
    end
  end
end

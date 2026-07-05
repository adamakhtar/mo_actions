module MoActions
  module Types
    class Datetime
      def initialize(**)
        @type = ActiveModel::Type::DateTime.new
      end

      def cast(raw)
        return Result.new(value: nil) if raw.nil? || raw == ""

        value = @type.cast(raw)
        value ? Result.new(value: value) : Result.new(error: "is not a datetime")
      end
    end
  end
end

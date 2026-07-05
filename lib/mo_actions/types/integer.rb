module MoActions
  module Types
    class Integer
      def initialize(**)
      end

      def cast(raw)
        return Result.new(value: nil) if raw.nil? || raw == ""

        Result.new(value: Kernel.Integer(raw))
      rescue ArgumentError, TypeError
        Result.new(error: "is not an integer")
      end
    end
  end
end

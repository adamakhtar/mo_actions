module MoActions
  module Types
    class Boolean
      def initialize(**)
        @type = ActiveModel::Type::Boolean.new
      end

      def cast(raw)
        Result.new(value: @type.cast(raw))
      end
    end
  end
end

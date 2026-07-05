module MoActions
  module Types
    class String
      def initialize(**)
        @type = ActiveModel::Type::String.new
      end

      def cast(raw)
        Result.new(value: @type.cast(raw))
      end
    end
  end
end

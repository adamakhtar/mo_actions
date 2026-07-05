module MoActions
  module Types
    class String
      def initialize(**)
      end

      def cast(raw)
        Result.new(value: raw.nil? ? nil : raw.to_s)
      end
    end
  end
end

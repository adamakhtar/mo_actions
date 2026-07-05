module MoActions
  module Types
    class File
      def initialize(**)
      end

      def cast(raw)
        Result.new(value: raw.presence)
      end
    end
  end
end

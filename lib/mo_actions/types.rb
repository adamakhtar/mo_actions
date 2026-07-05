require "bigdecimal"

module MoActions
  module Types
    Result = Struct.new(:value, :error, keyword_init: true) do
      def valid?
        error.nil?
      end
    end

    TYPE_CLASSES = {
      string: "MoActions::Types::String",
      integer: "MoActions::Types::Integer",
      decimal: "MoActions::Types::Decimal",
      boolean: "MoActions::Types::Boolean",
      date: "MoActions::Types::Date",
      datetime: "MoActions::Types::Datetime",
      enum: "MoActions::Types::Enum",
      file: "MoActions::Types::File"
    }.freeze

    def self.lookup(type, **options)
      TYPE_CLASSES.fetch(type.to_sym) { raise ArgumentError, "Unknown argument type #{type.inspect}" }.constantize.new(**options)
    end
  end
end

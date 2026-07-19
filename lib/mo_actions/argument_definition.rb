module MoActions
  class ArgumentDefinition
    TYPES = %i[string integer boolean].freeze

    attr_reader :name, :type, :description

    def initialize(name:, type: :string, description: nil)
      @name = name.to_sym
      @type = type.to_sym
      @description = description

      unless TYPES.include?(@type)
        raise ArgumentError, "unsupported argument type #{@type.inspect} (supported: #{TYPES.join(", ")})"
      end
    end

    # Light coercion only — no validation. Uncastable integers become nil.
    def cast(raw)
      case type
      when :string
        raw.nil? ? nil : raw.to_s
      when :integer
        return nil if raw.nil? || raw == ""
        Integer(raw, exception: false)
      when :boolean
        ActiveModel::Type::Boolean.new.cast(raw)
      end
    end
  end
end

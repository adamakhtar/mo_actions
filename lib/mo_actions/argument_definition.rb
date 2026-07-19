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

      @caster = ActiveModel::Type.lookup(@type)
    end

    # Light coercion only — no validation. Delegates to ActiveModel::Type
    # (same casters Rails uses for attributes/params).
    def cast(raw)
      @caster.cast(raw)
    end
  end
end

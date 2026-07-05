module MoActions
  class ArgumentDefinition
    attr_reader :name, :type, :default, :description, :validation_options, :array_validation_options, :type_options

    def initialize(name:, type:, array:, required:, default:, default_provided:, description:, validation_options:, array_validation_options:, type_options:)
      @name = name.to_sym
      @type = type.to_sym
      @array = array
      @required = required
      @default = default
      @default_provided = default_provided
      @description = description
      @validation_options = validation_options
      @array_validation_options = array_validation_options
      @type_options = type_options

      raise ArgumentError, "enum argument #{name.inspect} requires values:" if @type == :enum && Array(@type_options[:values]).empty?
    end

    def array?
      @array
    end

    def required?
      @required
    end

    def default?
      @default_provided
    end

    def type_object
      Types.lookup(type, **type_options)
    end
  end
end

module MoActions
  class Arguments
    attr_reader :action_class, :errors

    def self.build(action_class, raw_hash)
      new(action_class, raw_hash || {}).tap(&:validate)
    end

    def initialize(action_class, raw_hash)
      @action_class = action_class
      @raw_hash = raw_hash.to_h.with_indifferent_access
      @values = {}
      @errors = ActiveModel::Errors.new(self)
      define_readers
    end

    def [](name)
      @values[name.to_sym]
    end

    def valid?
      errors.empty?
    end

    def validate
      action_class.argument_definitions.each { |definition| cast_and_validate(definition) }
      self
    end

    def to_h
      @values.transform_values { |value| serialize(value) }
    end

    def read_attribute_for_validation(attribute)
      self[attribute]
    end

    def self.human_attribute_name(attribute, *)
      attribute.to_s
    end

    def self.lookup_ancestors
      [self]
    end

    private

    def cast_and_validate(definition)
      raw = raw_value_for(definition)

      if definition.array?
        cast_array(definition, raw)
      else
        cast_scalar(definition, definition.name, raw)
      end
    end

    def raw_value_for(definition)
      if @raw_hash.key?(definition.name)
        @raw_hash[definition.name]
      elsif definition.default?
        definition.default
      end
    end

    def cast_scalar(definition, error_key, raw)
      result = definition.type_object.cast(raw)
      @values[definition.name] = result.value if error_key == definition.name

      add_error(error_key, result.error) unless result.valid?
      validate_required(definition, error_key, result.value)
      validate_value(definition, error_key, result.value) if result.valid?
      result.value
    end

    def cast_array(definition, raw)
      values = normalize_array(raw)
      @values[definition.name] = values.each_with_index.map do |item, index|
        cast_scalar(definition, :"#{definition.name}[#{index}]", item)
      end

      validate_required(definition, definition.name, @values[definition.name])
      validate_array(definition)
    end

    def normalize_array(raw)
      return [] if raw.nil? || raw == ""

      Array(raw)
    end

    def validate_required(definition, error_key, value)
      add_error(error_key, "can't be blank") if definition.required? && blank_value?(value)
    end

    def validate_value(definition, error_key, value)
      return if blank_value?(value)

      options = definition.validation_options
      validate_presence(error_key, value) if options[:presence]
      validate_numericality(error_key, value, options[:numericality]) if options[:numericality]
      validate_inclusion(error_key, value, options[:inclusion]) if options[:inclusion]
      validate_custom(error_key, value, options[:validate] || options[:custom])
    end

    def validate_presence(error_key, value)
      add_error(error_key, "can't be blank") if blank_value?(value)
    end

    def validate_numericality(error_key, value, options)
      return add_error(error_key, "is not a number") unless value.is_a?(Numeric)

      checks = options == true ? {} : options
      add_error(error_key, "must be greater than #{checks[:greater_than]}") if checks[:greater_than] && value <= checks[:greater_than]
      add_error(error_key, "must be greater than or equal to #{checks[:greater_than_or_equal_to]}") if checks[:greater_than_or_equal_to] && value < checks[:greater_than_or_equal_to]
      add_error(error_key, "must be less than #{checks[:less_than]}") if checks[:less_than] && value >= checks[:less_than]
      add_error(error_key, "must be less than or equal to #{checks[:less_than_or_equal_to]}") if checks[:less_than_or_equal_to] && value > checks[:less_than_or_equal_to]
    end

    def validate_inclusion(error_key, value, options)
      allowed = options[:in] || options[:within]
      add_error(error_key, "is not included in #{allowed.join(', ')}") unless allowed.include?(value)
    end

    def validate_custom(error_key, value, rule)
      return unless rule

      result = rule.respond_to?(:call) ? rule.call(value) : action_class.public_send(rule, value)
      add_error(error_key, result.is_a?(String) ? result : "is invalid") if result == false || result.is_a?(String)
    end

    def validate_array(definition)
      options = definition.array_validation_options
      values = @values[definition.name]

      add_error(definition.name, "must have at least #{options[:min_items]} item(s)") if options[:min_items] && values.size < options[:min_items]
      add_error(definition.name, "must have at most #{options[:max_items]} item(s)") if options[:max_items] && values.size > options[:max_items]
      add_error(definition.name, "must contain unique values") if options[:unique] && values.compact.uniq.size != values.compact.size
    end

    def blank_value?(value)
      value.respond_to?(:empty?) ? value.empty? : value.nil?
    end

    def add_error(attribute, message)
      errors.add(attribute, message)
    end

    def serialize(value)
      case value
      when Array then value.map { |item| serialize(item) }
      when BigDecimal then value.to_s("F")
      when Date, Time then value.iso8601
      else value
      end
    end

    def define_readers
      action_class.argument_definitions.each do |definition|
        define_singleton_method(definition.name) { self[definition.name] }
      end
    end
  end
end

module MoActions
  class Arguments
    RAILS_VALIDATORS = {
      presence: ActiveModel::Validations::PresenceValidator,
      numericality: ActiveModel::Validations::NumericalityValidator,
      inclusion: ActiveModel::Validations::InclusionValidator
    }.freeze

    attr_reader :action_class, :errors

    def self.build(action_class, raw_hash) = new(action_class, raw_hash || {}).tap(&:validate)

    def initialize(action_class, raw_hash)
      @action_class = action_class
      @raw_hash = raw_hash.to_h.with_indifferent_access
      @values = {}
      @errors = ActiveModel::Errors.new(self)
      define_readers
    end

    def [](name) = @values[name.to_sym]

    def valid? = errors.empty?

    def validate
      action_class.argument_definitions.each { |definition| cast_and_validate(definition) }
      self
    end

    def to_h
      @values.transform_values { |value| serialize(value) }
    end

    def read_attribute_for_validation(attribute) = self[attribute]

    def self.human_attribute_name(attribute, *) = attribute.to_s

    def self.model_name = ActiveModel::Name.new(self, nil, "Arguments")

    def model_name = self.class.model_name

    def self.lookup_ancestors = [self]

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
      run_validator(:presence, error_key, result.value, {}) if definition.required?
      validate_value(definition, error_key, result.value) if result.valid?
      result.value
    end

    def cast_array(definition, raw)
      values = raw.nil? || raw == "" ? [] : Array(raw)
      @values[definition.name] = values.each_with_index.map do |item, index|
        cast_scalar(definition, :"#{definition.name}[#{index}]", item)
      end

      run_validator(:presence, definition.name, @values[definition.name], {}) if definition.required?
      validate_array(definition)
    end

    def validate_value(definition, error_key, value)
      options = definition.validation_options
      run_validator(:presence, error_key, value, {}) if options[:presence]
      return if blank_value?(value)

      run_validator(:numericality, error_key, value, options[:numericality]) if options[:numericality]
      run_validator(:inclusion, error_key, value, options[:inclusion]) if options[:inclusion]
      validate_custom(error_key, value, options[:validate] || options[:custom])
    end

    def run_validator(kind, error_key, value, options)
      validator_options = options == true ? {} : options
      RAILS_VALIDATORS.fetch(kind).new(validator_options.merge(attributes: [error_key])).validate_each(self, error_key, value)
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

    def add_error(attribute, message) = errors.add(attribute, message)

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

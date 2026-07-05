module MoActions
  module ArgumentsHelper
    PARTIALS = {
      string: "mo_actions/arguments/string",
      integer: "mo_actions/arguments/number",
      decimal: "mo_actions/arguments/number",
      boolean: "mo_actions/arguments/boolean",
      date: "mo_actions/arguments/date",
      datetime: "mo_actions/arguments/datetime",
      enum: "mo_actions/arguments/enum",
      file: "mo_actions/arguments/file"
    }.freeze

    def render_argument_field(form:, definition:, arguments:)
      if definition.array?
        render "mo_actions/arguments/array", form: form, definition: definition, arguments: arguments
      else
        render PARTIALS.fetch(definition.type), form: form, definition: definition, arguments: arguments
      end
    end

    def argument_value(arguments, definition)
      arguments[definition.name]
    end

    def argument_input_name(definition)
      "execution[arguments][#{definition.name}]"
    end

    def array_argument_input_name(definition)
      "#{argument_input_name(definition)}[]"
    end

    def argument_input_id(definition_or_name, index = nil)
      name = definition_or_name.respond_to?(:name) ? definition_or_name.name : definition_or_name
      ["execution_arguments", name, index].compact.join("_")
    end

    def argument_field_id(definition)
      "#{argument_input_id(definition)}_field"
    end

    def argument_error_anchor(attribute)
      match = attribute.to_s.match(/\A(.+)\[(\d+)\]\z/)
      return argument_input_id(match[1], match[2]) if match

      "#{argument_input_id(attribute)}_field"
    end

    def argument_error_label(attribute)
      attribute.to_s.sub(/\[(\d+)\]\z/, ' #\1').humanize
    end

    def argument_errors(arguments, definition, index = nil)
      key = index.nil? ? definition.name : :"#{definition.name}[#{index}]"
      arguments.errors[key]
    end

    def argument_required_label(definition)
      tag.span("required", class: "mo-actions-required") if definition.required?
    end

    def datetime_field_value(value)
      return if value.blank?

      Time.zone.parse(value.to_s).strftime("%Y-%m-%dT%H:%M")
    end

    def display_argument_value(arguments, definition)
      value = argument_value(arguments, definition)

      if definition.array?
        values = Array(value)
        return "Not provided" if values.empty?

        values.map { |item| display_scalar_argument_value(item, definition) }.join(", ")
      else
        display_scalar_argument_value(value, definition)
      end
    end

    def display_scalar_argument_value(value, definition)
      return "Not provided" if value.blank? && value != false

      case definition.type
      when :boolean
        value ? "Yes" : "No"
      when :decimal
        value.is_a?(BigDecimal) ? value.to_s("F") : value.to_s
      when :file
        "File uploads arrive in phase 7"
      else
        value.to_s
      end
    end
  end
end

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

    def argument_input_id(definition, index = nil)
      ["execution_arguments", definition.name, index].compact.join("_")
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
  end
end

module MoActions
  # Superclass for actions defined in the host app under app/actions.
  #
  #   class ImportUsersAction < MoActions::Base
  #     display_name "Import Users"
  #     description "Imports users from the nightly CSV export."
  #     category :billing
  #
  #     argument :source, type: :string
  #     argument :notify, type: :boolean, description: "Email ops when done"
  #
  #     def perform
  #       # source, notify available as readers
  #     end
  #   end
  class Base
    class << self
      def inherited(subclass)
        super
        MoActions::Registry.register(subclass)
      end

      # Stable identifier, derived from the class name by default:
      # ImportUsersAction => "import_users"
      def key(value = nil)
        @key = value.to_s if value
        @key ||= name.demodulize.delete_suffix("Action").underscore
      end

      def display_name(value = nil)
        @display_name = value if value
        @display_name ||= key.humanize
      end

      def description(value = nil)
        @description = value if value
        @description
      end

      def category(value = nil)
        @category = value.to_sym if value
        @category or raise MoActions::MissingCategory,
          "#{name} has no category. Declare one with `category :some_category`."
      end

      def argument(name, type: :string, description: nil)
        definition = ArgumentDefinition.new(name: name, type: type, description: description)
        arguments.reject! { |existing| existing.name == definition.name }
        arguments << definition
        attr_reader definition.name
      end

      def arguments
        @arguments ||= []
      end
    end

    def initialize(raw_arguments = {})
      raw = raw_arguments.to_h.with_indifferent_access
      self.class.arguments.each do |definition|
        instance_variable_set(:"@#{definition.name}", definition.cast(raw[definition.name]))
      end
    end

    # Coerced argument values keyed by name (string), suitable for persistence.
    def argument_values
      self.class.arguments.each_with_object({}) do |definition, hash|
        hash[definition.name.to_s] = public_send(definition.name)
      end
    end

    def perform
      raise NotImplementedError, "#{self.class.name} must implement #perform"
    end
  end
end

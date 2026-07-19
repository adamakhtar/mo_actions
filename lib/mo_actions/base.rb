module MoActions
  # Superclass for actions defined in the host app under app/actions.
  #
  #   class ImportUsersAction < MoActions::Base
  #     display_name "Import Users"
  #     description "Imports users from the nightly CSV export."
  #     category :billing
  #
  #     argument :source, type: :string, required: true
  #     argument :notify, type: :boolean, description: "Email ops when done"
  #
  #     def perform
  #       # source, notify available as readers after #cast_arguments!
  #     end
  #   end
  #
  # Dashboard flow: assign raw params → +valid?+ → +cast_arguments!+ → +perform+.
  class Base
    include ActiveModel::Model

    validate :validate_arguments

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

      def argument(name, type: :string, description: nil, required: false)
        definition = ArgumentDefinition.new(
          name: name,
          type: type,
          description: description,
          required: required
        )
        arguments.reject! { |existing| existing.name == definition.name }
        arguments << definition
        attr_accessor definition.name
      end

      def arguments
        @arguments ||= []
      end
    end

    def initialize(raw_arguments = {})
      super(raw_argument_attributes(raw_arguments))
    end

    # Coerce accessors in place. Call only after +valid?+.
    def cast_arguments!
      self.class.arguments.each do |definition|
        public_send("#{definition.name}=", definition.cast(public_send(definition.name)))
      end
      self
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

    private

    def raw_argument_attributes(raw_arguments)
      raw = raw_arguments.to_h.with_indifferent_access
      self.class.arguments.each_with_object({}) do |definition, hash|
        hash[definition.name] = raw[definition.name] if raw.key?(definition.name)
      end
    end

    # Validate raw submitted values before casting so integer checks see
    # "abc" rather than ActiveModel::Type::Integer's 0.
    def validate_arguments
      self.class.arguments.each do |definition|
        value = public_send(definition.name)

        if definition.required? && value.blank?
          errors.add(definition.name, :blank)
        end

        next unless definition.type == :integer
        next if value.blank?

        unless integer_string?(value)
          errors.add(definition.name, :not_a_number)
        end
      end
    end

    def integer_string?(value)
      return true if value.is_a?(Integer)

      value.to_s.match?(/\A[+-]?\d+\z/)
    end
  end
end

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
  #     def perform(ctx)
  #       ctx.total = rows.size
  #       rows.each_with_index { |row, i| import(row); ctx.progress(i + 1) }
  #     end
  #   end
  #
  # Prefer +execute+ (validates, casts, persists a running Execution, enqueues
  # the job) over calling +perform+ directly.
  class Base
    include ActiveModel::Model

    attr_reader :execution

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

        # Rails validators — declared at definition time so hosts get normal
        # ActiveModel errors/I18n. Values are still raw here; cast after valid?
        validates definition.name, presence: true if definition.required?

        if definition.type == :integer
          validates definition.name, numericality: { only_integer: true }, allow_blank: true
        end
      end

      def arguments
        @arguments ||= []
      end
    end

    # Coerced argument values keyed by name (string), suitable for persistence.
    # Populated after a successful validation + cast inside +execute+.
    def argument_values
      self.class.arguments.each_with_object({}) do |definition, hash|
        hash[definition.name.to_s] = public_send(definition.name)
      end
    end

    # Validate raw input, cast, persist a running Execution, and enqueue work.
    # Returns false without side effects when invalid. The job records
    # succeeded/failed on the same execution.
    def execute(performer: nil)
      return false unless valid?

      cast_arguments!

      @execution = Execution.create!(
        action_key: self.class.key,
        arguments: argument_values,
        performer: performer,
        status: "running",
        progress_current: 0
      )
      RunExecutionJob.perform_later(@execution.id)

      true
    end

    def perform(ctx)
      raise NotImplementedError, "#{self.class.name} must implement #perform"
    end

    private

    def cast_arguments!
      self.class.arguments.each do |definition|
        public_send("#{definition.name}=", definition.cast(public_send(definition.name)))
      end
    end
  end
end

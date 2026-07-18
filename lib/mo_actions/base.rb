module MoActions
  # Superclass for actions defined in the host app under app/actions.
  #
  #   class ImportUsersAction < MoActions::Base
  #     display_name "Import Users"
  #     description "Imports users from the nightly CSV export."
  #     category :billing
  #
  #     def perform
  #       # ...
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
    end

    def perform
      raise NotImplementedError, "#{self.class.name} must implement #perform"
    end
  end
end

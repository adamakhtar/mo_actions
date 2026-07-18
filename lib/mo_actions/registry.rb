module MoActions
  # Holds every action class known to the app. Populated by
  # MoActions::Base.inherited as action files are loaded, and rebuilt on each
  # code reload (see MoActions::Engine).
  module Registry
    class << self
      def register(klass)
        actions << klass unless actions.include?(klass)
        klass
      end

      def find(key)
        actions.find { |a| a.key == key.to_s } or
          raise MoActions::ActionNotFound, "No action registered with key #{key.inspect}"
      end

      def all
        actions.dup
      end

      def by_category
        actions
          .sort_by { |a| a.display_name }
          .group_by(&:category)
          .sort_by { |category, _| category.to_s }
          .to_h
      end

      def reset!
        actions.clear
      end

      private

      def actions
        @actions ||= []
      end
    end
  end
end

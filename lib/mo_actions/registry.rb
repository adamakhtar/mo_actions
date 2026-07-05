module MoActions
  module Registry
    class DuplicateKey < StandardError
    end

    class MissingCategory < StandardError
    end

    class << self
      def register(klass)
        raise MissingCategory, "#{class_name_for(klass)} must declare a category, e.g. category :maintenance" unless klass.category?

        key = klass.key
        existing = actions[key]

        if existing && existing != klass
          raise DuplicateKey, "MoActions key #{key.inspect} is already registered by #{class_name_for(existing)}; #{class_name_for(klass)} cannot reuse it"
        end

        actions_by_class.delete(klass)&.then { |old_key| actions.delete(old_key) }
        actions[key] = klass
        actions_by_class[klass] = key
        klass
      end

      def find(key)
        actions.fetch(key.to_s)
      rescue KeyError
        raise ActionNotFound, "No MoActions action registered for #{key.inspect}"
      end

      def all
        actions.values.sort_by(&:name)
      end

      def by_category
        all.group_by(&:category).sort_by { |category, _actions| category.to_s }.to_h
      end

      def reset!
        actions.clear
        actions_by_class.clear
      end

      def rebuild!
        reset!
        Base.known_actions.each { |klass| register(klass) }
      end

      private

      def actions
        @actions ||= {}
      end

      def actions_by_class
        @actions_by_class ||= {}
      end

      def class_name_for(klass)
        klass.respond_to?(:action_class_name) ? klass.action_class_name : klass.name
      end
    end
  end
end

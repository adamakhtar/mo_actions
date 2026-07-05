module MoActions
  class Base
    class << self
      def inherited(subclass)
        super
        known_actions << subclass
      end

      def known_actions
        @known_actions ||= []
      end

      def action_class_name
        Module.instance_method(:name).bind_call(self)
      end

      # These are Rails-style DSL macros (`name "Import Users"`), not Ruby
      # attribute writers, so action classes stay concise and match the plan.
      def key(value = nil)
        if value.nil?
          @key || derived_key
        else
          @key = value.to_s
          Registry.register(self) if category?
        end
      end

      def name(value = nil)
        if value.nil?
          @name || key.humanize
        else
          @name = value.to_s
        end
      end

      def description(value = nil)
        if value.nil?
          @description
        else
          @description = value.to_s
        end
      end

      def category(value = nil)
        if value.nil?
          @category
        else
          @category = value.to_sym
          Registry.register(self)
        end
      end

      def category?
        @category.present?
      end

      private

      def derived_key
        if action_class_name.blank?
          raise ArgumentError, "MoActions action classes must be named to derive a key"
        end

        action_class_name.demodulize.sub(/Action\z/, "").underscore
      end
    end
  end
end

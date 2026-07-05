module MoActions
  class Base
    UNSET = Object.new

    class << self
      def inherited(subclass)
        super
        known_actions << subclass
      end

      def known_actions
        @known_actions ||= []
      end

      def key(value = UNSET)
        if value.equal?(UNSET)
          @key || derived_key
        else
          @key = value.to_s
          Registry.register(self) if category?
        end
      end

      def name(value = UNSET)
        if value.equal?(UNSET)
          @name || key.humanize
        else
          @name = value.to_s
        end
      end

      def description(value = UNSET)
        if value.equal?(UNSET)
          @description
        else
          @description = value.to_s
        end
      end

      def category(value = UNSET)
        if value.equal?(UNSET)
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
        if self.name.blank?
          raise ArgumentError, "MoActions action classes must be named to derive a key"
        end

        self.name.demodulize.sub(/Action\z/, "").underscore
      end
    end
  end
end

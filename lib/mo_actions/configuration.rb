module MoActions
  class Configuration
    attr_accessor :performer_class_name, :authenticate_with, :current_performer

    def initialize
      @performer_class_name = "User"
      @authenticate_with = nil
      @current_performer = nil
    end

    def performer_class
      performer_class_name.constantize
    end
  end
end

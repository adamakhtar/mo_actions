module MoActions
  class Configuration
    attr_accessor :authenticate_with, :current_performer

    def initialize
      @authenticate_with = nil
      @current_performer = nil
    end
  end
end

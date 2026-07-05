require "mo_actions/version"
require "mo_actions/configuration"
require "mo_actions/engine"

module MoActions
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    def reset_config!
      @config = Configuration.new
    end
  end
end

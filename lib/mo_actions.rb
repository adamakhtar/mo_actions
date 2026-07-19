require "mo_actions/version"
require "mo_actions/configuration"

module MoActions
  class Error < StandardError; end
  class ActionNotFound < Error; end
  class MissingCategory < Error; end

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

require "mo_actions/argument_definition"
require "mo_actions/registry"
require "mo_actions/base"
require "mo_actions/engine"


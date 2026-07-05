require "mo_actions/version"
require "mo_actions/action_not_found"
require "mo_actions/invalid_transition"
require "mo_actions/argument_definition"
require "mo_actions/types"
require "mo_actions/types/string"
require "mo_actions/types/integer"
require "mo_actions/types/decimal"
require "mo_actions/types/boolean"
require "mo_actions/types/date"
require "mo_actions/types/datetime"
require "mo_actions/types/enum"
require "mo_actions/types/file"
require "mo_actions/arguments"
require "mo_actions/configuration"
require "mo_actions/registry"
require "mo_actions/base"
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

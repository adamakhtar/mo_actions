require "mo_actions/version"

module MoActions
  class Error < StandardError; end
  class ActionNotFound < Error; end
  class MissingCategory < Error; end
end

require "mo_actions/registry"
require "mo_actions/base"
require "mo_actions/engine"

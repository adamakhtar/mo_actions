require "rails"
require "turbo-rails"
require "stimulus-rails"

module MoActions
  class Engine < ::Rails::Engine
    isolate_namespace MoActions
  end
end

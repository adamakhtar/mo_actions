ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment"
require "rails/test_help"

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.timestamps
  end
end

class ActiveSupport::TestCase
  setup do
    MoActions.reset_config!
  end
end

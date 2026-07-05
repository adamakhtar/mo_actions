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
    rediscover_dummy_actions
  end

  private

  def rediscover_dummy_actions
    MoActions::Registry.reset!
    Dir[Rails.root.join("app/actions/**/*_action.rb")].sort.each { |file| load file }
  end
end

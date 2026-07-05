ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment"
require "rails/test_help"

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :mo_actions_executions, force: true do |t|
    t.string :action_key, null: false
    t.string :status, null: false, default: "draft"
    t.references :performer, polymorphic: true, null: false, index: true
    t.json :arguments, null: false, default: {}
    t.json :preflight_results, default: {}
    t.text :error_message
    t.integer :progress, null: false, default: 0
    t.datetime :queued_at
    t.datetime :started_at
    t.datetime :finished_at
    t.timestamps
  end

  add_index :mo_actions_executions, :action_key
  add_index :mo_actions_executions, :status

  create_table :mo_actions_batches, force: true do |t|
    t.references :execution, null: false, foreign_key: { to_table: :mo_actions_executions }
    t.integer :position, null: false
    t.string :status, null: false, default: "pending"
    t.integer :progress, null: false, default: 0
    t.text :error_message
    t.json :checkpoint, default: {}
    t.datetime :started_at
    t.datetime :finished_at
    t.timestamps
  end

  add_index :mo_actions_batches, [:execution_id, :position], unique: true

  create_table :mo_actions_log_entries, force: true do |t|
    t.references :execution, null: false, foreign_key: { to_table: :mo_actions_executions }
    t.references :batch, foreign_key: { to_table: :mo_actions_batches }
    t.string :level, null: false
    t.text :message, null: false
    t.datetime :created_at, null: false
  end

  add_index :mo_actions_log_entries, :created_at
end

class ActiveSupport::TestCase
  fixtures :all

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

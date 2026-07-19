# frozen_string_literal: true

# Prefer jsonb on PostgreSQL; Rails' :json works on SQLite (dummy/tests) and PG alike.
class CreateMoActionsExecutions < ActiveRecord::Migration[7.0]
  def change
    create_table :mo_actions_executions do |t|
      t.string :action_key, null: false
      t.string :status, null: false
      t.references :performer, polymorphic: true, null: true
      t.json :arguments, null: false, default: {}
      t.text :error_message

      t.timestamps
    end

    add_index :mo_actions_executions, :action_key
    add_index :mo_actions_executions, :status
    add_index :mo_actions_executions, :created_at
  end
end

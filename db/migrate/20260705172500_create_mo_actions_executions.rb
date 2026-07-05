class CreateMoActionsExecutions < ActiveRecord::Migration[7.0]
  def change
    create_table :mo_actions_executions do |t|
      t.string :action_key, null: false
      t.string :status, null: false, default: "draft"
      t.references :performer, polymorphic: true, null: false, index: true
      t.public_send(json_column_type, :arguments, null: false, default: {})
      t.public_send(json_column_type, :preflight_results, default: {})
      t.text :error_message
      t.integer :progress, null: false, default: 0
      t.datetime :queued_at
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
    end

    add_index :mo_actions_executions, :action_key
    add_index :mo_actions_executions, :status
  end

  private

  # PostgreSQL hosts get jsonb; SQLite in the dummy app uses json.
  def json_column_type
    connection.adapter_name == "PostgreSQL" ? :jsonb : :json
  end
end

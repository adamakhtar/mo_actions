class CreateMoActionsBatches < ActiveRecord::Migration[7.0]
  def change
    create_table :mo_actions_batches do |t|
      t.references :execution, null: false, foreign_key: { to_table: :mo_actions_executions }
      t.integer :position, null: false
      t.string :status, null: false, default: "pending"
      t.integer :progress, null: false, default: 0
      t.text :error_message
      t.public_send(json_column_type, :checkpoint, default: {})
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
    end

    add_index :mo_actions_batches, [:execution_id, :position], unique: true
  end

  private

  # PostgreSQL hosts get jsonb; SQLite in the dummy app uses json.
  def json_column_type
    connection.adapter_name == "PostgreSQL" ? :jsonb : :json
  end
end

class CreateMoActionsLogEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :mo_actions_log_entries do |t|
      t.references :execution, null: false, foreign_key: { to_table: :mo_actions_executions }
      t.references :batch, foreign_key: { to_table: :mo_actions_batches }
      t.string :level, null: false
      t.text :message, null: false
      t.datetime :created_at, null: false
    end

    add_index :mo_actions_log_entries, :created_at
  end
end

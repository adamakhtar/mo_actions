# frozen_string_literal: true

class AddProgressToMoActionsExecutions < ActiveRecord::Migration[7.0]
  def change
    add_column :mo_actions_executions, :progress_current, :integer, null: false, default: 0
    add_column :mo_actions_executions, :progress_total, :integer
  end
end

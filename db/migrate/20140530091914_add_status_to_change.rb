class AddStatusToChange < ActiveRecord::Migration
  def change
    change_table :changes do |t|
      t.integer :status, default: 0, null: false
    end
  end
end

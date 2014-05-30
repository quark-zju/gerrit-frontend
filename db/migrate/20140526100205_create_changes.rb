class CreateChanges < ActiveRecord::Migration
  def change
    create_table :changes do |t|
      t.references :host, index: true
      t.string :change_id, null: false, index: true
      t.string :subject, null: false
      t.integer :number, null: false, index: true
      t.references :project, index: true
      t.string :branch
      t.references :owner
      t.timestamps
    end

    add_index :changes, [:host_id, :number], unique: true
  end
end

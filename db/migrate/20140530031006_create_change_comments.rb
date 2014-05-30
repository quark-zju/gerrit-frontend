class CreateChangeComments < ActiveRecord::Migration
  def change
    create_table :change_comments do |t|
      t.references :author, null: false, index: true
      t.references :change, null: false, index: true
      t.string :local_id, null: false, index: true
      t.integer :revision_number
      t.text :message

      t.timestamps
    end
  end
end

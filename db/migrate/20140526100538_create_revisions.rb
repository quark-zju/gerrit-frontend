class CreateRevisions < ActiveRecord::Migration
  def change
    create_table :revisions do |t|
      t.references :change, null: false, index: true
      t.integer :local_id, null: false
      t.string :parent_commit
      t.string :author
      t.string :committer
      t.string :subject
      t.text :message
    end
  end
end

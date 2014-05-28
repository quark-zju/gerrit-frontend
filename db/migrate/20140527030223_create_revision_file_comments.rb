class CreateRevisionFileComments < ActiveRecord::Migration
  def change
    create_table :revision_file_comments do |t|
      t.references :revision_file, index: true
      t.integer :line
      t.text :message
      t.references :author, index: true

      t.timestamps
    end
  end
end

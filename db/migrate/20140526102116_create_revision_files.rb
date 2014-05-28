class CreateRevisionFiles < ActiveRecord::Migration
  def change
    create_table :revision_files do |t|
      t.references :revision, null: false, index: true
      t.string :pathname, null: false
      t.text :a
      t.text :b
    end
  end
end

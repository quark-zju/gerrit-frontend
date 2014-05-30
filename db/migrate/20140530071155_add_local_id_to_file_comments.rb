class AddLocalIdToFileComments < ActiveRecord::Migration
  def change
    change_table :revision_file_comments do |t|
      t.string :local_id, index: true
    end
  end
end

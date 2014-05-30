class AddCompressedContentToFiles < ActiveRecord::Migration
  def change
    change_table :revision_files do |t|
      t.binary :compressed_a
      t.binary :compressed_b
    end
  end
end

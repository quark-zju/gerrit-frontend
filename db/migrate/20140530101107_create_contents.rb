class CreateContents < ActiveRecord::Migration
  def change
    create_table :contents do |t|
      t.string :digest, null: false
      t.binary :compressed_content, null: false
    end

    add_index :contents, :digest, unique: true
  end
end

class CreateHosts < ActiveRecord::Migration
  def change
    create_table :hosts do |t|
      t.string :base_url, null: false, index: true
    end
  end
end

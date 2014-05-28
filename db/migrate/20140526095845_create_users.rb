class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.references :host, null: false, index: true
      t.string :name, null: false
      t.string :username, null: false
      t.string :email, null: false
      t.integer :account_id, null: false
    end
  end
end

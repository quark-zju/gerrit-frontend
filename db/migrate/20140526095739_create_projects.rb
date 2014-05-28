class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.references :host, index: true
      t.string :name, null: false
    end
  end
end

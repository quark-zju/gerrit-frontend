class AddAllowAnonymousToHosts < ActiveRecord::Migration
  def change
    change_table :hosts do |t|
      t.boolean :allow_anonymous, default: false, null: false
    end
  end
end

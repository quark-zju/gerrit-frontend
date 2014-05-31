class AddIsLocalNetToHosts < ActiveRecord::Migration
  def change
    change_table :hosts do |t|
      t.boolean :is_local_net, default: false, null: false
    end
  end
end

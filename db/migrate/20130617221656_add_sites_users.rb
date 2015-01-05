class AddSitesUsers < ActiveRecord::Migration
  def change
    create_table :sites_users, :id => false do |t|
      t.references :site, :null => false, :default => 0
      t.references :user, :null => false, :default => 0
      t.boolean :dropped, :null => false, :default => 0
    end
    add_index :sites_users, :site_id
    add_index :sites_users, :user_id
    add_index :sites_users, :dropped
  end
end

class AddRolesUsers < ActiveRecord::Migration
  def change
    create_table :roles_users, :id => false do |t|
      t.references :site, :null => false, :default => 0
      t.references :role, :null => false, :default => 0
      t.references :user, :null => false, :default => 0
    end
    add_index :roles_users, :site_id
    add_index :roles_users, :role_id
    add_index :roles_users, :user_id
  end
end

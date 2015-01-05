class RefactorForBetterModels < ActiveRecord::Migration
  def up
    rename_table :sites_users, :memberships
    rename_table :roles_users, :memberships_siteroles
    rename_table :roles_sites, :siteroles
    rename_table :meetings_users, :attendances
    
    add_column :siteroles, :id, :primary_key, :first => true
    
    add_column :memberships, :id, :primary_key, :first => true
    rename_column :memberships, :dropped, :active
    
    remove_column :memberships_siteroles, :site_id
    rename_column :memberships_siteroles, :user_id, :membership_id
    rename_column :memberships_siteroles, :role_id, :siterole_id
  end
  
  def down
    # no down
  end
end

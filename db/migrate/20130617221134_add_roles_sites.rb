class AddRolesSites < ActiveRecord::Migration
  def change
    create_table :roles_sites, :id => false do |t|
      t.references :site, :null => false, :default => 0
      t.references :role, :null => false, :default => 0
      t.boolean :take_attendance, :null => false, :default => 0
    end
    add_index :roles_sites, :site_id
    add_index :roles_sites, :role_id
  end
end

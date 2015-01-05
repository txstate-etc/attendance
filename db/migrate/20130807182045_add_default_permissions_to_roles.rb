class AddDefaultPermissionsToRoles < ActiveRecord::Migration
  def up
    add_column :roles, :take_attendance, :boolean, :null => false, :default => 0
    add_column :roles, :record_attendance, :boolean, :null => false, :default => 0
  end
  def down
    remove_column :roles, :take_attendance
    remove_column :roles, :record_attendance
  end
end

class SetInactiveDefaultAttendancetype < ActiveRecord::Migration
  def up
    add_column :attendancetypes, :default_inactive, :boolean, :null => false, :default => 0
    add_index :attendancetypes, :default_inactive
  end

  def down
    remove_column :attendancetypes, :default_inactive
  end
end

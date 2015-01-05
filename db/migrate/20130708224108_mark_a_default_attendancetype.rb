class MarkADefaultAttendancetype < ActiveRecord::Migration
  def up
    add_column :attendancetypes, :default_type, :boolean, :null => false, :default => 0
    add_index :attendancetypes, :default_type
  end

  def down
    remove_column :attendancetypes, :default_type
  end
end

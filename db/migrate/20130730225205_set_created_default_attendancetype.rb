class SetCreatedDefaultAttendancetype < ActiveRecord::Migration
  def up
    add_column :attendancetypes, :default_created, :boolean, :null => false, :default => 0
    add_index :attendancetypes, :default_created
  end

  def down
    remove_column :attendancetypes, :default_created
  end
end

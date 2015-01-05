class DisplayOrderAttendancetypes < ActiveRecord::Migration
  def up
    add_column :attendancetypes, :display_order, :integer, :limit => 1, :null => false, :default => 0
    add_index :attendancetypes, :display_order
  end

  def down
    remove_column :attendancetypes, :display_order
  end
end

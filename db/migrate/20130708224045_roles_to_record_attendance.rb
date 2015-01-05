class RolesToRecordAttendance < ActiveRecord::Migration
  def up
    add_column :siteroles, :record_attendance, :boolean, :null => false, :default => 0
  end

  def down
    remove_column :siteroles, :record_attendance
  end
end

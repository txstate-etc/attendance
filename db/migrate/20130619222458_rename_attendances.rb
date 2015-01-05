class RenameAttendances < ActiveRecord::Migration
  def up
    rename_table :attendances, :userattendances
  end

  def down
  end
end

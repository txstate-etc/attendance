class AddGradeTypeToAttendancetypes < ActiveRecord::Migration
  def change
    add_column :attendancetypes, :grade_type, :integer, null: false, default: 0
  end
end

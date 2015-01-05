class AddTardyPerAbsenceToGradesettings < ActiveRecord::Migration
  def change
    add_column :gradesettings, :tardy_per_absence, :integer, default: 0, null: false
  end
end

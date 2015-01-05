class AddDeductionToGradesettings < ActiveRecord::Migration
  def change
    add_column :gradesettings, :deduction, :decimal, null: false, default: 0, precision: 3, scale: 2
  end
end

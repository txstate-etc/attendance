class AddEditGradesettingsToSiterole < ActiveRecord::Migration
  def change
    add_column :siteroles, :edit_gradesettings, :boolean, null: false, default: 0
  end
end

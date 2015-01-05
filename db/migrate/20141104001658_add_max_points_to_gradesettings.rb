class AddMaxPointsToGradesettings < ActiveRecord::Migration
  def change
    add_column :gradesettings, :max_points, :integer, null: false, default: 100
    add_column :gradesettings, :auto_max_points, :boolean, null: false, default: true
  end
end

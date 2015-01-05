class ChangeAutoMaxPointsDefault < ActiveRecord::Migration
  def up
    change_column :gradesettings, :auto_max_points, :boolean, null: false, default: false
  end

  def down
    change_column :gradesettings, :auto_max_points, :boolean, null: false, default: true
  end
end

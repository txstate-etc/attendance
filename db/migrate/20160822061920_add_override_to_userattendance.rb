class AddOverrideToUserattendance < ActiveRecord::Migration
  def change
    add_column :userattendances, :override, :boolean, null: false, default: false
  end
end

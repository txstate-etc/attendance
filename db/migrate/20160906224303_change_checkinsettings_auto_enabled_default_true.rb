class ChangeCheckinsettingsAutoEnabledDefaultTrue < ActiveRecord::Migration
  def up
    change_column :checkinsettings, :auto_enabled, :boolean, default: true
  end

  def down
    change_column :checkinsettings, :auto_enabled, :boolean, default: false
  end
end

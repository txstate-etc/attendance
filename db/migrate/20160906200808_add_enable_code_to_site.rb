class AddEnableCodeToSite < ActiveRecord::Migration
  def change
    add_column :sites, :enable_code, :boolean, null: false, default: false
  end
end

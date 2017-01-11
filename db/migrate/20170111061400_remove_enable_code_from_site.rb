class RemoveEnableCodeFromSite < ActiveRecord::Migration
  def change
    remove_column :sites, :enable_code
  end
end

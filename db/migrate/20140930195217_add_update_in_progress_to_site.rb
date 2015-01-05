class AddUpdateInProgressToSite < ActiveRecord::Migration
  def change
    add_column :sites, :update_in_progress, :datetime
  end
end

class AddOutcomesUrlToSites < ActiveRecord::Migration
  def change
    add_column :sites, :outcomes_url, :string
  end
end

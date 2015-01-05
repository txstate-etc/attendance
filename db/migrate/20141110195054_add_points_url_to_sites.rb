class AddPointsUrlToSites < ActiveRecord::Migration
  def change
    add_column :sites, :points_url, :string
  end
end

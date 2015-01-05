class AddRosterHashToSites < ActiveRecord::Migration
  def change
    add_column :sites, :roster_hash, :string, null: false, default: ""
  end
end

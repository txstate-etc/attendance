class TrackLastRosterUpdate < ActiveRecord::Migration
  def up
    add_column :sites, :roster_fetched_at, :datetime, :null => false, :default => 0
  end

  def down
    remove_column :sites, :roster_fetched_at
  end
end

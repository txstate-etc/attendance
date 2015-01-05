class CreateRosterupdates < ActiveRecord::Migration
  def change
    create_table :binaries do |t|
      t.string :sha1, :null => false
      t.binary :data, :null => false, :limit => 15.megabyte
    end
    add_index :binaries, :sha1
    
    create_table :rosterupdates do |t|
      t.references :site, :null => false
      t.references :binary, :null => false
      t.datetime :fetched_at, :null => false
    end
    add_index :rosterupdates, [:site_id, :fetched_at]
    add_index :rosterupdates, :binary_id
  end
end

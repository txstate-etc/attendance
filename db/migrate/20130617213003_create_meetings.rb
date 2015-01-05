class CreateMeetings < ActiveRecord::Migration
  def change
    create_table :meetings do |t|
      t.references :site, :null => false, :default => 0
      t.datetime :starttime, :null => false, :default => 0
      t.boolean :cancelled, :null => false, :default => 0
      t.boolean :deleted, :null => false, :default => 0
      t.datetime :updated_at, :null => false, :default => 0
    end
    add_index :meetings, :site_id
    add_index :meetings, :updated_at
  end
end

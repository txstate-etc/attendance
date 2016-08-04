class AddIdToUserattendance < ActiveRecord::Migration
  def up
    add_column :userattendances, :id, :primary_key
    add_index :userattendances, [:meeting_id, :membership_id], :unique => true
  end
  def down
    remove_column :userattendances, :id
    remove_index :userattendances, [:meeting_id, :membership_id]
  end
end

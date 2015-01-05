class AddMeetingsUsers < ActiveRecord::Migration
  def change
    create_table :meetings_users, :id => false do |t|
      t.references :meeting, :null => false, :default => 0
      t.references :user, :null => false, :default => 0
      t.references :attendancetype, :null => false, :default => 0
      t.datetime :updated_at, :null => false, :default => 0
    end
    add_index :meetings_users, :meeting_id
    add_index :meetings_users, :user_id
    add_index :meetings_users, :attendancetype_id
  end
end

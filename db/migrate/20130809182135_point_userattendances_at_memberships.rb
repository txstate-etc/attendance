class PointUserattendancesAtMemberships < ActiveRecord::Migration
  def up
    add_column :userattendances, :membership_id, :integer, :null => false, :after => :meeting_id
    add_index :userattendances, :membership_id
    remove_column :userattendances, :user_id
  end

  def down
    add_column :userattendances, :user_id, :integer, :null => false, :after => :meeting_id
    add_index :userattendances, :user_id
    remove_column :userattendances, :membership_id
  end
end

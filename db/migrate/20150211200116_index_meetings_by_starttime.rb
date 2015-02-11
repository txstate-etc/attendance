class IndexMeetingsByStarttime < ActiveRecord::Migration
  def up
    add_index :meetings, :starttime
  end

  def down
    remove_index :meetings, :starttime
  end
end

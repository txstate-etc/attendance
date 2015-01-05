class AddIndexForCancelledMeetings < ActiveRecord::Migration
  def up
    remove_index :meetings, :site_id
    add_index :meetings, [:site_id, :deleted, :cancelled]
  end

  def down
    remove_index :meetings, [:site_id, :deleted, :cancelled]
    add_index :meetings, :site_id
  end
end

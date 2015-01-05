class IndexUsersByTcUserId < ActiveRecord::Migration
  def up
    add_index :users, :tc_user_id
  end

  def down
    remove_index :users, :tc_user_id
  end
end

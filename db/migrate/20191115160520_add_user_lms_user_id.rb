class AddUserLmsUserId < ActiveRecord::Migration
  def up
    add_column :users, :lms_user_id, :string, null: false, default: ''
  end

  def down
    remove_column :users, :lms_user_id
  end
end

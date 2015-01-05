class AddTcUserIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :tc_user_id, :string, {null: false, default: ""}
  end
end

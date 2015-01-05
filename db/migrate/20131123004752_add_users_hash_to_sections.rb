class AddUsersHashToSections < ActiveRecord::Migration
  def change
    add_column :sections, :users_hash, :string, null: false, default: ""
  end
end

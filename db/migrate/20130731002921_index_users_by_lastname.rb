class IndexUsersByLastname < ActiveRecord::Migration
  def up
    add_index :users, :lastname
  end

  def down
    remove_index :users, :lastname
  end
end

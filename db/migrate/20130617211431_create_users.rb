class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :netid, :null => false, :default => ""
      t.string :lastname, :null => false, :default => ""
      t.string :firstname, :null => false, :default => ""
      t.string :fullname, :null => false, :default => ""
      t.boolean :admin, :null => false, :default => 0
    end
    add_index :users, :netid
  end
end

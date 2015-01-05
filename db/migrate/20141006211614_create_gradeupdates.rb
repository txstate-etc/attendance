class CreateGradeupdates < ActiveRecord::Migration
  def change
    create_table :gradeupdates do |t|
      t.references :membership, :null => false
      t.integer :tries, :null => false, :default => 0

      t.timestamps
    end
    add_index :gradeupdates, :membership_id
  end
end

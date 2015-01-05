class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string :roletype, :null => false, :default => ""
      t.string :subroletype, :null => false, :default => ""
      t.string :roleurn, :null => false, :default => ""
      t.string :displayname, :null => false, :default => ""
      t.integer :displayorder, :null => false, :default => 0, :limit => 1
      t.boolean :sets_permissions, :null => false, :default => 0
    end
  end
end

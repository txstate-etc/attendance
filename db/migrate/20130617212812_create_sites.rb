class CreateSites < ActiveRecord::Migration
  def change
    create_table :sites do |t|
      t.string :context_id, :null => false, :default => ""
      t.string :context_label, :null => false, :default => ""
      t.string :context_name, :null => false, :default => ""
    end
    add_index :sites, :context_id
  end
end

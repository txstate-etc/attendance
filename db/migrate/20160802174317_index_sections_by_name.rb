class IndexSectionsByName < ActiveRecord::Migration
  def up
    add_index :sections, :name
  end

  def down
    remove_index :sections, :name
  end
end

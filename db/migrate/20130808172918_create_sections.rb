class CreateSections < ActiveRecord::Migration
  def up
    create_table :sections do |t|
      t.references :site, :null => false
      t.string :name, :null => false, :default => ''
    end
    add_index :sections, :site_id
    
    add_column :meetings, :section_id, :integer, :null => false
    add_index :meetings, :section_id
    remove_column :meetings, :site_id
    
    create_table :memberships_sections, :id => false do |t|
      t.references :section, :null => false
      t.references :membership, :null => false
    end
    add_index :memberships_sections, :section_id
    add_index :memberships_sections, :membership_id
  end
end

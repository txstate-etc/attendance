class SectionNameNotNull < ActiveRecord::Migration
  def up
    Section.where('name IS NULL').update_all(:name => '')
    change_column :sections, :name, :string, null: false, default: ''
  end

  def down
    change_column :sections, :name, :string, null: true
  end
end

class SectionNameNotNull < ActiveRecord::Migration
  def up
    change_column :sections, :name, :string, null: false, default: ''
  end

  def down
    change_column :sections, :name, :string, null: true
  end
end

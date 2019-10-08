class AddSectionDisplayName < ActiveRecord::Migration
  def up
    add_column :sections, :display_name, :string, null: false, default: ''
  end

  def down
    remove_column :sections, :display_name
  end
end

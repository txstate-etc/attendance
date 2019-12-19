class SectionNameNotNull < ActiveRecord::Migration
  def up
    Section.connection.execute("UPDATE sections SET name='' WHERE name IS NULL")
    change_column :sections, :name, :string, null: false, default: ''
  end

  def down
    change_column :sections, :name, :string, null: true
  end
end

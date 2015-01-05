class CreateAttendanceTypes < ActiveRecord::Migration
  def change
    create_table :attendancetypes do |t|
      t.string :name, :null => false, :default => ""
      t.text :description, :null => false, :default => ""
      t.integer :display_column, :null => false, :default => 0, :limit => 1
      t.string :color, :null => false, :default => ""
      t.boolean :absent, :null => false, :default => 0
    end
    add_index :attendancetypes, :absent
  end
end

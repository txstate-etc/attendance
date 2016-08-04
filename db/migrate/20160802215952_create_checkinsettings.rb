class CreateCheckinsettings < ActiveRecord::Migration
  def change
    create_table :checkinsettings do |t|
      t.references :site
      t.boolean :auto_enabled, null: false, default: true
      t.integer :tardy_after, null: false, default: 15
      t.integer :absent_after, null: false, default: 30

      t.timestamps
    end
    add_index :checkinsettings, :site_id
  end
end

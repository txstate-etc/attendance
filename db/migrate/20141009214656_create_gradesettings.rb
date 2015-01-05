class CreateGradesettings < ActiveRecord::Migration
  def change
    create_table :gradesettings do |t|
      t.references :site
      t.decimal :tardy_value, null: false, default: 1.0, precision: 3, scale: 2
      t.integer :forgiven_absences, null: false, default: 0
    end
    add_index :gradesettings, :site_id
  end
end

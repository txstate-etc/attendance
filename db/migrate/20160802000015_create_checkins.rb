class CreateCheckins < ActiveRecord::Migration
  def change
    create_table :checkins do |t|
      t.references :userattendance
      t.datetime :time
      t.string :source
    end
    add_index :checkins, :userattendance_id
  end
end

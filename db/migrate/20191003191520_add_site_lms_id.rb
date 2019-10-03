class AddSiteLmsId < ActiveRecord::Migration
  def up
    add_column :sites, :lms_id, :string, null: false, default: ''
    add_column :sites, :is_canvas, :boolean, null: false, default: 0
  end

  def down
    remove_column :sites, :lms_id
    remove_column :sites, :is_canvas
  end
end

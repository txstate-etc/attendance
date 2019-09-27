class AddSectionLmsId < ActiveRecord::Migration
  def up
    add_column :sections, :lms_id, :string, null: false, default: ''
  end

  def down
    remove_column :sections, :lms_id
  end
end

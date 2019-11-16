class AddSiteAssignmentId < ActiveRecord::Migration
  def up
    add_column :sites, :assignment_id, :string, null: false, default: ''
  end

  def down
    remove_column :sites, :assignment_id
  end
end

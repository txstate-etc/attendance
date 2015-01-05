class UnassignedUpgradeTask < ActiveRecord::Migration
  def up
    add_column :sections, :is_default, :boolean, null: false, default: 0

    Section.update_all("name='Unassigned', is_default=1", "name = 'default'")
  end

  def down
    # not reversible!
  end
end

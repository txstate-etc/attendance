class AddSourcedidToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :sourcedid, :string
  end
end

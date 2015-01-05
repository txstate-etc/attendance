class AddLastErrorToGradeupdate < ActiveRecord::Migration
  def change
    add_column :gradeupdates, :last_error, :string
  end
end

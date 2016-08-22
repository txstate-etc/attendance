class AddSourceStarttimeToMeeting < ActiveRecord::Migration
  def change
    add_column :meetings, :source_starttime, :datetime
  end
end

class AddFutureMeetingToMeeting < ActiveRecord::Migration
  class Meeting < ActiveRecord::Base
  end

  def change
    add_column :meetings, :future_meeting, :boolean, null: false, default: false
    Meeting.where('starttime > ?', Time.now).update_all(:future_meeting => true)
  end
end

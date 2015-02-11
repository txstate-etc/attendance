class SetFutureMeetingFlags < ActiveRecord::Migration
  class Meeting < ActiveRecord::Base
  end

  def up
    Meeting.where('starttime > ? and starttime > updated_at', Time.utc(2015)).update_all(:future_meeting => true)
  end
end

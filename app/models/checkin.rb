class Checkin < ActiveRecord::Base
  belongs_to :userattendance, inverse_of: :checkins
  attr_accessible :source, :time
end

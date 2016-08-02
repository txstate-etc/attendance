class Userattendance < ActiveRecord::Base
  belongs_to :membership, :inverse_of => :userattendances
  belongs_to :meeting, :inverse_of => :userattendances
  belongs_to :attendancetype, :inverse_of => :userattendances

  has_many :checkins, dependent: :destroy, inverse_of: :userattendance, after_add: :update_checkin

  after_save {|ua| Gradeupdate.register_change(ua.membership.id) if ua.membership.site.outcomes_url}
    
  self.primary_keys = [:meeting_id, :membership_id]
  
  def self.record_attendance(meetingid, membershipid, attendancetypeid)
    ua = Userattendance.unscoped.where(:membership_id => membershipid, :meeting_id => meetingid).first_or_create
    ua.attendancetype_id = attendancetypeid
    ua.save
    ua.errors.to_a
  end
  
  def cached_attendancetype
    Attendancetype.fetch(self.attendancetype_id)
  end
  
  # after calling this function, we will use the provided hash on
  # the membership association, instead of making a database call
  def cache_membership(membership_hash)
    @cached_membership = membership_hash.fetch(self.membership_id, nil)
  end
  
  def membership
    @cached_membership || super
  end

  def update_checkin(checkin)
    self.attendancetype = Attendancetype.find_by_name('present')
    self.save
  end
end

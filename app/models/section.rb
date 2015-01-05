class Section < ActiveRecord::Base
  attr_accessible :name, :site_id
  
  belongs_to :site, :inverse_of => :sections
  has_and_belongs_to_many :memberships
  has_many :meetings, :inverse_of => :section, :dependent => :destroy
  
  def userattendances
    Userattendance.joins(:meeting, {membership: :siteroles}).where(:meetings => { :deleted => false, :cancelled => false, :section_id => self.id }, :siteroles => { :record_attendance => true })
  end
  
  def past_attendances
    userattendances.where('meetings.starttime < ?', Time.zone.now)
  end
  
  def recorded_memberships
    memberships.joins(:siteroles).where(:siteroles => {:record_attendance => true})
  end
  
  def valid_meetings
    self.meetings.where(:cancelled => false, :deleted => false)
  end
  
  def valid_meeting_count
    @valid_meeting_count ||= self.valid_meetings.count
  end
  
  def past_meetings
    valid_meetings.where('starttime < ?', Time.zone.now)
  end
  
  def past_meeting_count
    @past_meeting_count ||= past_meetings.count
  end
  
  def safe_name
    name.gsub(/\W+/, '_')
  end
  
  def useful_name
    is_default ? site.context_name : name
  end
end

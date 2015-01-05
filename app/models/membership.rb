class Membership < ActiveRecord::Base
  attr_accessible :active, :sourcedid

  belongs_to :site, :inverse_of => :memberships
  belongs_to :user, :inverse_of => :memberships
  has_many :userattendances, :dependent => :destroy

  has_and_belongs_to_many :sections,
    :after_add => :react_to_recordedstatus_change,
    :after_remove => :react_to_lost_section
  has_and_belongs_to_many :siteroles,
    :after_add => :react_to_recordedstatus_change

  after_update :react_to_status_change
  def react_to_status_change
    if self.active_changed? && self.record_attendance?
      self.total_meetings.each do |m|
        Userattendance.record_attendance(m.id, self.id, default_atype.id) if m.starttime > Time.zone.now
      end
    end
    true
  end

  after_create :react_to_new_memberships
  def react_to_new_memberships
    return true unless self.record_attendance?
    now = Time.zone.now
    self.total_meetings.each do |m|
      # all past meetings are set to the created_default (probably 'Excused' or something like that)
      # all future meetings are set to the default based on their membership status
      Userattendance.record_attendance(m.id, self.id, m.starttime >= now ? default_atype.id : Attendancetype.created_default.id)
    end
    true
  end

  def react_to_recordedstatus_change(siterole)
    if self.record_attendance?
      mtgs = self.total_meetings
      untouchables = {}
      Userattendance.where(:meeting_id => mtgs.map(&:id), :membership_id => self.id).each do |ua|
        untouchables[ua.meeting_id.to_s+ua.membership_id.to_s] = true;
      end
      now = Time.zone.now
      mtgs.each do |m|
        if m.starttime > now || !untouchables[m.id.to_s+self.id.to_s]
          Userattendance.record_attendance(m.id, self.id, m.starttime >= now ? default_atype.id : Attendancetype.created_default.id)
        end
      end
    end
  end

  def react_to_lost_section(section)
    Userattendance.includes(:meeting => :section).where(:meetings => { :section_id => section.id }).where('meetings.starttime > ?', Time.zone.now).destroy_all(:membership_id => self.id)
  end

  def remove_from_section(section)
    Userattendance.includes(:meeting => :section).where(:meetings => { :section_id => section.id }).destroy_all(:membership_id => self.id)
    self.sections.destroy(section)
    if self.sections.empty?
      self.destroy
    end
  end

  def total_meetings
    recorded_sections.map(&:valid_meetings).flatten
  end

  def set_permissions?
    siteroles.any? { |sr| sr.set_permissions? }
  end

  def record_attendance?
    siteroles.any? { |sr| sr.record_attendance? }
  end

  def take_attendance?
    siteroles.any? { |sr| sr.take_attendance? }
  end

  def edit_gradesettings?
    siteroles.any? { |sr| sr.edit_gradesettings? }
  end

  def default_atype
    self.active ? Attendancetype.default : Attendancetype.inactive_default
  end

  def valid_attendances(section)
    @valid_attendances ||= {}
    @valid_attendances[section.id] ||= userattendances.includes(:meeting => :section).where(:meetings => { :cancelled => false, :deleted => false, :section_id => section })
  end

  def recorded_attendances(section)
    @recorded_attendances ||= {}
    @recorded_attendances[section.id] ||= valid_attendances(section).where('meetings.starttime < ?', Time.zone.now).order('meetings.starttime')
  end

  def appearances(section)
    @appearances ||= {}
    @appearances[section.id] ||= recorded_attendances(section).select { |ua| !ua.cached_attendancetype.absent }
  end

  def last_attended(section)
    appearances(section).map(&:meeting).map(&:starttime).max
  end

  def recorded_meetings(section)
    @valid_meetings ||= {}
    @valid_meetings[section.id] ||= section.valid_meetings.where('starttime < ?', Time.zone.now)
  end

  def recorded_sections
    sections || [site.default_section]
  end
end

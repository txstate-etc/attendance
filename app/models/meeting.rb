class Meeting < ActiveRecord::Base
  attr_accessible :cancelled, :deleted, :starttime
  attr_accessor :initial_atype

  default_scope where(:deleted => false)
  
  belongs_to :section, :inverse_of => :meetings
  has_many :userattendances, :inverse_of => :meeting, :dependent => :destroy
  
  after_save :update_max_points, :update_grade
  before_save 'attendances_merged!'
  
  def userattendances_hash
    if @ua_hash.nil?
      @ua_hash = {}
      userattendances.each do |ua|
        @ua_hash[ua.membership_id] = true
      end
    end
    @ua_hash
  end
  
  def attendances_merged!(mysection = nil)
    mysection ||= section
    mysection.memberships.includes(:user, :siteroles).each do |m|
      next unless m.record_attendance?
      if !self.userattendances_hash[m.id]
        ua = userattendances.build
        ua.membership = m
        ua.attendancetype = @initial_atype && m.active ? @initial_atype : m.default_atype
        self.userattendances_hash[m.id] = true
      end
    end
    true
  end
  
  def active
    !(cancelled || deleted)
  end

  def update_grade
    Gradeupdate.register_site_change(self.section.site)
    return true
  end

  def update_max_points
    return true if self.section.site.points_url.nil? || self.section.site.max_points_section.nil?
    return true if self.section.id != self.section.site.max_points_section.id
    settings = Gradesettings.find_by_site_id(self.section.site.id)
    return true if settings.nil? || !settings.auto_max_points
    Gradeupdate.update_max_points(settings)
    return true
  end
end

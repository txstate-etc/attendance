class Siterole < ActiveRecord::Base
  attr_accessible :record_attendance, :take_attendance, :edit_gradesettings

  belongs_to :site, :inverse_of => :siteroles
  belongs_to :role, :inverse_of => :siteroles
  has_and_belongs_to_many :memberships
  
  after_update :react_to_permission_change
  before_create :set_default_permissions
  
  def react_to_permission_change
    if self.record_attendance_changed? && self.record_attendance
      self.memberships.each do |m|
        m.react_to_recordedstatus_change(self)
      end
    end
    true
  end
  
  def set_default_permissions
    self.record_attendance = role.record_attendance
    self.take_attendance = role.take_attendance
    self.edit_gradesettings = role.edit_gradesettings
    true
  end
  
  def set_permissions?
    role.sets_permissions
  end
end

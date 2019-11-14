class Gradesettings < ActiveRecord::Base
  belongs_to :site, :inverse_of => :gradesettings
  attr_accessible :forgiven_absences, :tardy_value, :deduction, :tardy_per_absence, :auto_max_points, :max_points

  validates :forgiven_absences, on: :update,
            numericality: {
              only_integer: true,
              greater_than: -1,
              message: 'Number of forgiven absences must be a non-negative integer'
            }
  validates :tardy_value, on: :update,
            numericality: {
              only_integer: true,
              greater_than: -1,
              less_than: 101,
              message: 'Tardy value must be an integer between 0 and 100'
            }
  validates :deduction, on: :update,
            numericality: {
              only_integer: true,
              greater_than: -1,
              less_than: 101,
              message: 'Deduction per absence must be a non-negative integer between 0 and 100'
            }
  validates :tardy_per_absence, on: :update,
            numericality: {
              only_integer: true,
              greater_than: -1,
              message: 'Tardy per absence must be a non-negative integer'
            }
  validates :max_points, on: :update,
            numericality: {
              only_integer: true,
              greater_than: 0,
              message: 'Max points must be a positive integer'
            }

  after_validation on: :update do
    self.tardy_value = self.tardy_value / 100.0
    self.deduction = self.deduction / 100.0
  end

  before_validation on: :update do
    self.tardy_value = (self.tardy_value * 100).to_i
    self.deduction = (self.deduction * 100.0).to_i
  end

  before_update do
    site = Site.find_by_id(self.site_id)
    if(!site.is_canvas)
      if self.max_points_changed? || self.auto_max_points_changed? || self.auto_max_points
        return false unless Gradeupdate.update_max_points(self)
      end
    end
  end

  after_update {|settings| Gradeupdate.register_site_change(settings.site)}

  def self.save_max_points(siteid, maxPoints)
    settings = Gradesettings.find_or_initialize_by_site_id(siteid)
    settings.assign_attributes(
      max_points: maxPoints.to_i
    )
    settings.save if settings.max_points_changed?
  end

end

class Gradesettings < ActiveRecord::Base
  belongs_to :site
  attr_accessible :forgiven_absences, :tardy_value, :deduction, :tardy_per_absence, :auto_max_points, :max_points

  after_update {|settings| Gradeupdate.register_site_change(settings.site)}
end

class Checkinsettings < ActiveRecord::Base
  belongs_to :site, inverse_of: :checkinsettings
  attr_accessible :absent_after, :auto_enabled, :tardy_after

  validates :tardy_after,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              message: 'Tardy after must be a non-negative integer'
            }
  validates :absent_after,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              message: 'Absent after must be a non-negative integer'
            }
  validate :tardy_after_lte_absent_after

  def tardy_after_lte_absent_after
    errors.add(:tardy_after, 'Tardy after must be less than or equal to absent after') if tardy_after > absent_after
  end
end

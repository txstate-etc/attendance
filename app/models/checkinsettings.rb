class Checkinsettings < ActiveRecord::Base
  belongs_to :site, inverse_of: :checkinsettings
  attr_accessible :absent_after, :auto_enabled, :tardy_after

  # TODO: add validation
end

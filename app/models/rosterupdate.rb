class Rosterupdate < ActiveRecord::Base
  belongs_to :binary
  belongs_to :site
  
  # normally you'd do this with :dependent => :destroy, but that runs on
  # the before_destroy callback.  We need this to run on after_destroy so
  # the binary can check whether it is truly orphaned before it allows itself
  # to be deleted
  after_destroy :destroy_binary
  def destroy_binary
    self.binary.destroy
    return true
  end
  
  def self.log(site, xml)
    r = Rosterupdate.new
    r.fetched_at = Time.zone.now
    r.site = site
    r.binary = Binary.grab(ActiveSupport::Gzip.compress(xml))
    r.save
  end
end

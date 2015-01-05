class Binary < ActiveRecord::Base
  attr_accessible :sha1, :data
  
  def data=(bytes)
    super(bytes)
    self.sha1 = Digest::SHA1.base64digest(bytes)
  end
  
  def self.grab(bytes)
    Binary.find_or_create_by_sha1(:sha1 => Digest::SHA1.base64digest(bytes), :data => bytes)
  end
  
  before_destroy :is_orphan
  def is_orphan
    # only allow destruction if binary is orphaned (returning false cancels the destroy)
    return Rosterupdate.where('binary_id = ?', self.id).count == 0
  end

end

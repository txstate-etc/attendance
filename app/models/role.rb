class Role < ActiveRecord::Base
  attr_accessible :displayname, :displayorder, :roletype, :roleurn, :sets_permissions, :subroletype, :take_attendance, :record_attendance, :edit_gradesettings
  has_many :siteroles, :inverse_of => :role, :dependent => :destroy

  def self.getRolesFromString(roles)
    roles_hash = {};

    # Role names are either the full urn or the handle for a context role.
    # If the role can't be found in the db, it will be ignored.
    roles.split(',').each do |rolestring|
      if rolestring =~ /urn:lti:(.*):ims\/lis\/(.*)/
        role = Role.find_by_roleurn(rolestring)
        roles_hash[role.id] = role unless role.nil?
      else
        role = Role.find_by_roleurn('urn:lti:role:ims/lis/' + rolestring)
        roles_hash[role.id] = role unless role.nil?
      end
    end
    roles_hash
  end
end

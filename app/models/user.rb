class User < ActiveRecord::Base
  attr_accessible :admin, :firstname, :fullname, :lastname, :netid, :tc_user_id, :lms_user_id

  has_many :memberships, :inverse_of => :user, :dependent => :destroy
  has_many :sites, :through => :memberships
  has_many :userattendances, :inverse_of => :user, :dependent => :destroy

  def self.netidfromshibb(loginid)
    loginid.split(/@/, 2)[0]
  end

  def self.from_launch_params(params)
    netid = params['custom_canvas_user_login_id'].nil? ? params['lis_person_sourcedid'] : User.netidfromshibb(params['custom_canvas_user_login_id'])
    user = User.find_or_initialize_by_netid(netid)
    user.assign_attributes(
      firstname: params['lis_person_name_given'] || '',
      lastname: params['lis_person_name_family'] || '',
      fullname: params['lis_person_name_full'],
      netid: netid,
      tc_user_id: params['user_id'],
      admin: !(params['roles'] =~ /ims\/lis\/Administrator/).nil?,
      lms_user_id: params['custom_canvas_user_id'].nil? ? params['user_id'] :  params['custom_canvas_user_id']
    )
    user.save
    user
  end

  def self.from_roster_xml(xmlnode, user = nil)
    user ||= User.find_or_initialize_by_tc_user_id(xmlnode.find_first('user_id').content)
    firstname_node = xmlnode.find_first('person_name_given')
    lastname_node = xmlnode.find_first('person_name_family')
    fullname_node = xmlnode.find_first('person_name_full')
    netid_node = xmlnode.find_first('person_sourcedid')

    user.firstname = firstname_node.content if firstname_node
    user.lastname = lastname_node.content if lastname_node
    user.fullname = fullname_node.content if fullname_node
    user.netid = netid_node.content if netid_node

    user.save if user.changed?
    user
  end

  def self.from_canvas_api(netid, info, user = nil)
    user ||= User.find_or_initialize_by_netid(netid)
    firstlast = info[:user][:short_name].split(/\s+/, 2)
    user.firstname = firstlast[0]
    user.lastname = firstlast[1] if firstlast.count == 2
    user.fullname = info[:user][:name]
    user.lms_user_id = info[:user_id]

    user.save if user.changed?
    user
  end

  ##
  # Creates membership if it does not exist. If membership does exist,
  # makes sure that membership.siteroles is the same as the roles hash.
  # ***NOTE: roles hash might be modified.***
  ##
  def verify_membership(site, roles, isActive, sections, membership, sourcedid = nil)
    unless membership
      membership = self.memberships.build()
      membership.site_id = site.id
    end
    membership.active = isActive

    # Remove any siteroles that aren't in roles param
    membership.siteroles.select { |siterole| !roles.delete(siterole.role.id) }.map { |siterole| membership.siteroles.destroy(siterole) }

    # Add any siteroles from roles param that don't exist already
    roles.each do |role_id, role|
      # Admin is not a siterole. This might change in the future?
      continue if role.roleurn =~ /admin/i
      unless siterole = site.siteroles.find_by_role_id(role.id)
        siterole = site.siteroles.build()
        siterole.role_id = role_id
        site.save
      end
      membership.siteroles.push(siterole)
    end

    membership.sourcedid = sourcedid || membership.sourcedid

    membership.save if membership.changed?
    membership.sections = sections if sections && sections.count > 0 && sections != membership.sections

    # Add user to unassigned section if they don't have any sections
    if membership.sections.empty? && record_attendance?(site)
      membership.sections.push(site.default_section)
    end

    membership
  end

  def set_permissions?(site)
    site = site.id if site.is_a?(Site)
    return self.admin || memberships.find_by_site_id(site).set_permissions? rescue false
  end

  def take_attendance?(site)
    site = site.id if site.is_a?(Site)
    return self.admin || memberships.find_by_site_id(site).take_attendance? rescue false
  end

  def record_attendance?(site)
    site = site.id if site.is_a?(Site)
    return memberships.find_by_site_id(site).record_attendance? rescue false
  end

  def edit_gradesettings?(site)
    site = site.id if site.is_a?(Site)
    return self.admin || memberships.find_by_site_id(site).edit_gradesettings? rescue false
  end

  # returns a User, if one doesn't exist for that netid it gets created
  def self.bynetid(netid)
    return nil if netid.blank?
    User.find_or_create_by_netid(:netid => netid, :admin => false)
  end

  def membership_for_site(site)
    site.memberships.find_by_user_id(self.id)
  end

  def sections_to_choose(site)
    @sectionstochoose ||= (take_attendance?(site) ? site.non_empty_sections : site.sections_for_user(self)).to_a
  end
end

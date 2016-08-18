module UsersHelper
  def intro_page_for_site(site, user)
    unless user.take_attendance?(site)
      ua = Userattendance.joins(:membership, meeting: :section)
        .where(sections: {site_id: site})
        .where('meetings.checkin_code is not null')
        .where(memberships: {user_id: user})
        .first

      return enter_code_userattendance_path(ua) unless ua.nil? || !ua.checkins.empty?
    end

    return site_path(site) if user.sections_to_choose(site).count > 1
    section = user.sections_to_choose(site).first
    return intro_page_for_section(section, user) if !section.nil?
    if user.set_permissions?(site)
      flash[:notice] = "This site is not set up to track attendance for any users. Please select the roles that should have their attendance tracked."
      return edit_perms_site_path(site)
    end
    return '/static/nostudents' if user.take_attendance?(site)
    return '/static/notready'
  end
  
  def intro_page_for_section(section, user)
    user.take_attendance?(section.site) ? section_path(section) : section_membership_path(section, user.membership_for_site(section.site))
  end
end

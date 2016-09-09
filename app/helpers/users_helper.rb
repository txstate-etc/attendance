module UsersHelper
  def intro_page_for_site(site, user)
    unless user.take_attendance?(site)
      ua = Userattendance.joins('left join `checkins` on userattendances.id = checkins.userattendance_id')
        .joins(:membership, meeting: :section)
        .includes(meeting: {section: {site: :checkinsettings}})
        .where(sections: {site_id: site})
        .where(meetings: {deleted: false, cancelled: false})
        .where('meetings.checkin_code is not null')
        .where(memberships: {user_id: user})
        .where('checkins.id is null')
        .find{|ua| ua.meeting.checkin_active?}

      return enter_code_userattendance_path(ua) unless ua.nil?
    end

    return site_path(site) if user.sections_to_choose(site).count > 1
    section = user.sections_to_choose(site).first
    return intro_page_for_section(section, user) if !section.nil?
    if user.edit_gradesettings?(site)
      flash[:notice] = "This site is not set up to track attendance for any users. Please select the roles that should have their attendance tracked."
      return edit_settings_site_path(site)
    end
    return '/static/nostudents' if user.take_attendance?(site)
    return '/static/notready'
  end
  
  def intro_page_for_section(section, user)
    user.take_attendance?(section.site) ? section_path(section) : section_membership_path(section, user.membership_for_site(section.site))
  end
end

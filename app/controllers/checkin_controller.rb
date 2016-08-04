class CheckinController < ApplicationController

  def create
    user = User.find_by_netid(params['netid'])
    render nothing: true, status: 204 and return unless user
    section = Membership.find_by_user_id(user).sections.find_by_name(params['providerId'])
    render nothing: true, status: 204 and return unless section
    settings = Checkinsettings.find_or_create_by_site_id(section.site)
    render nothing: true, status: 204 and return unless settings.auto_enabled

    membership = section.memberships.find_by_user_id(user)
    meeting = section.meetings
      .create_with(initial_atype: Attendancetype.find_by_name('absent'))
      .find_or_create_by_starttime(Time.at(params['sessionStart']/1000))

    ua = meeting.userattendances.find_by_membership_id(membership)
    if ua.checkins.empty?
      checkin = ua.checkins.create({source: params['source'], time: Time.at(params['time']/1000)})
    end

    render nothing: true, status: 204
  end

  # TODO: add authentication
  private
  def authorize
    return true
  end
end

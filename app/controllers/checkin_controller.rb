class CheckinController < ApplicationController

  def section
    user = User.find_by_netid(params['netid'])
    head :no_content and return unless user
    section = Membership.find_by_user_id(user).sections.find_by_name(params['providerId'])
    head :no_content and return unless section
    settings = Checkinsettings.find_or_create_by_site_id(section.site)
    head :no_content and return unless settings.auto_enabled

    membership = section.memberships.find_by_user_id(user)
    meeting = section.meetings
      .create_with(initial_atype: Attendancetype.find_by_name('absent'))
      .find_or_create_by_starttime(Time.at(params['sessionStart']/1000))

    ua = meeting.userattendances.find_by_membership_id(membership)
    if ua.checkins.empty?
      ua.checkins.create({source: params['source'], time: Time.at(params['time']/1000)})
    end

    head :no_content
  end

  def code
    @ua ||= Userattendance.find(params[:ua])

    head :no_content unless @ua.checkins.empty?
    render 'invalid code', status: :bad_request and return unless @ua.meeting.checkin_code == params[:code]

    @ua.checkins.create({source: 'code', time: Time.now})
    head :no_content
  end

  # TODO: add authentication
  private
  def authorize
    return super do
      @ua ||= Userattendance.find(params[:id])
      @auth_user.id == @ua.membership.user_id
    end if ['code'].include?(action_name)
    return true if request.authorization == Attendance::Application.config.checkin_token
    return super
  end
end

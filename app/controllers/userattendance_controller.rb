class UserattendanceController < ApplicationController

  def code
    @ua ||= Userattendance.find(params[:id])
    head :no_content and return unless @ua.checkins.empty?

    if @ua.meeting.checkin_code == params[:code]
      @ua.checkins.create({source: 'code', time: Time.now})
      redirect_to section_membership_path(@ua.meeting.section, @ua.membership)
    else
      redirect_to enter_code_userattendance_path(@ua), notice: 'Invalid code'
    end
  end

  def enter_code
    @ua ||= Userattendance.find(params[:id])
  end

private
  def authorize
    return super do
      @ua ||= Userattendance.find(params[:id])
      @auth_user.id == @ua.membership.user_id
    end
  end
end

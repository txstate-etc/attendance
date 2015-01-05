require 'test_helper'

class MeetingsControllerTest < ActionController::TestCase
  setup do
    @meeting = meetings(:nextweek)
    @controller.class.skip_before_filter :authorize
  end

  test "should get new" do
    get :new, section_id: @meeting.section
    assert_response :success
  end

  test "should create meeting" do
    assert_difference('Meeting.count') do
      post :create, section_id: @meeting.section, meeting_startdate: @meeting.starttime.strftime('%Y-%m-%d'), meeting_starttime: @meeting.starttime.strftime('%-l:%M%P'), initial_atype: Attendancetype.default.id
    end

    assert_redirected_to section_path(assigns(:meeting).section)
  end

  test "should show meeting" do
    get :show, id: @meeting
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @meeting
    assert_response :success
  end

  test "should update meeting" do
    put :update, id: @meeting, meeting: { cancelled: @meeting.cancelled, deleted: @meeting.deleted, starttime: @meeting.starttime }
    assert_redirected_to section_path(assigns(:meeting).section)
  end
end

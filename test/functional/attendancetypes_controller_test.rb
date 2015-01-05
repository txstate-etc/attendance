require 'test_helper'

class AttendancetypesControllerTest < ActionController::TestCase
  setup do
    @attendancetype = attendancetypes(:present)
    @controller.class.skip_before_filter :authorize
    @controller.class.skip_before_filter :cas_require
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:attendancetypes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create attendancetype" do
    assert_difference('Attendancetype.count') do
      post :create, attendancetype: { 
        absent: @attendancetype.absent, 
        color: @attendancetype.color, 
        description: @attendancetype.description, 
        display_column: @attendancetype.display_column, 
        name: @attendancetype.name,
        default_type: @attendancetype.default_type,
        default_inactive: @attendancetype.default_inactive,
        default_created: @attendancetype.default_created
      }
    end

    assert_redirected_to attendancetype_path(assigns(:attendancetype))
  end

  test "should show attendancetype" do
    get :show, id: @attendancetype
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @attendancetype
    assert_response :success
  end

  test "should update attendancetype" do
    put :update, id: @attendancetype, attendancetype: { absent: @attendancetype.absent, color: @attendancetype.color, description: @attendancetype.description, display_column: @attendancetype.display_column, name: @attendancetype.name }
    assert_redirected_to attendancetype_path(assigns(:attendancetype))
  end
end

require 'test_helper'

class RolesControllerTest < ActionController::TestCase
  setup do
    @role = roles(:learner)
    @controller.class.skip_before_filter :authorize
    @controller.class.skip_before_filter :cas_require
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:roles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create role" do
    assert_difference('Role.count') do
      post :create, role: { displayname: @role.displayname, displayorder: @role.displayorder, roletype: @role.roletype, roleurn: @role.roleurn, sets_permissions: @role.sets_permissions, subroletype: @role.subroletype }
    end

    assert_redirected_to role_path(assigns(:role))
  end

  test "should show role" do
    get :show, id: @role
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @role
    assert_response :success
  end

  test "should update role" do
    put :update, id: @role, role: { displayname: @role.displayname, displayorder: @role.displayorder, roletype: @role.roletype, roleurn: @role.roleurn, sets_permissions: @role.sets_permissions, subroletype: @role.subroletype }
    assert_redirected_to role_path(assigns(:role))
  end
end

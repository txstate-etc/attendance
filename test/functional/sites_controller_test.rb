require 'test_helper'

class SitesControllerTest < ActionController::TestCase
  setup do
    @site = sites(:one)
    @controller.class.skip_before_filter :authorize
    @controller.instance_variable_set(:@auth_user, users(:nw13))
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sites)
  end

  test "should show site" do
    get :show, id: @site
    assert_response :success
  end
end

require 'test_helper'
require 'ims/lti'
require 'oauth/request_proxy/rack_request'

class LaunchControllerTest < ActionController::TestCase
  setup do
    @ltiparams = {
      'launch_url' => 'http://test.host/lti_tool',
      'title' => 'Attendance',
      'resource_link_id' => 'auniqueid',
      'roles' => 'instructor',
      'lis_person_name_given' => 'Test',
      'lis_person_name_family' => 'User',
      'lis_person_name_full' => 'Test A. User',
      'user_id' => 'some_user_id',
      'context_id' => 'a_course_id'
    }
    @consumer = IMS::LTI::ToolConsumer.new('tracs.txstate.edu', Attendance::Application.config.oauth_secret, @ltiparams);
  end

  test 'should return unauthorized on request without any data' do
    post :index
    assert_response 401
  end

  test 'should return unauthorized if consumer key is invalid' do
    @consumer.consumer_key = 'asd;lfjxcboyuaw'
    post "index", @consumer.generate_launch_data

    assert_response 401
  end

  test 'should return unauthorized if secret is invalid' do
    @consumer.consumer_secret = 'sdgfyuq,.vcxs'
    post :index, @consumer.generate_launch_data

    assert_response 401
  end

  # TODO: Tests below aren't working because of something to do with OAuth lib not handling
  # the test request properly. Need to figure this out! 
  #test 'should return success with valid signature' do
  #  post :index, @consumer.generate_launch_data

  #  assert_response :success
  #end

  test 'should return unauthorized if request is older than 5 minutes' do
    launch_data = @consumer.generate_launch_data
    post :index, launch_data

    time = Time.now + 5.minutes
    Timecop.travel(time)

    post :index, launch_data

    assert_response 401
  end

  test 'should return unauthorized if nonce has already been used' do
    launch_data = @consumer.generate_launch_data
    post :index, launch_data
    post :index, launch_data

    assert_response 401
  end
end

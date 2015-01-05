require 'test_helper'

class SiteTest < ActiveSupport::TestCase
  setup do
    @params = {
      "launch_presentation_css_url"=>"http://chriss-mac-pro.its.txstate.edu:8080/library/skin/default/tool.css", "ext_lms"=>"sakai2", "ext_sakai_server"=>"http://chriss-mac-pro.its.txstate.edu:8080", "oauth_nonce"=>"1372886104320318000", "oauth_consumer_key"=>"tracs.txstate.edu", "context_label"=>"Test 101 Label", "ext_ims_lis_memberships_url"=>"http://chriss-mac-pro.its.txstate.edu:8080/imsblis/service/", "lis_person_name_family"=>"Administrator", "resource_link_id"=>"914d63b6-0929-4cf3-8fc1-2ece233406b3", "oauth_callback"=>"about:blank", "oauth_signature"=>"F1WEqM+pTvjGX4A0daf6K8qAVRo=", "lti_version"=>"LTI-1p0", "oauth_signature_method"=>"HMAC-SHA1", "lti_message_type"=>"basic-lti-launch-request", "user_id"=>"admin", "user_image"=>"http://chriss-mac-pro.its.txstate.edu:8080/direct/profile/admin/image", "resource_link_description"=>"Attendance", "context_title"=>"Test 101", "oauth_version"=>"1.0", "ext_ims_lis_memberships_id"=>"eb5d7d956292d791864dfb4de9867f07c2bfc297174da68a13cbf5d2a1f21bc9:::admin:::914d63b6-0929-4cf3-8fc1-2ece233406b3", "lis_person_sourcedid"=>"admin", "context_type"=>"CourseSection", "ext_sakai_serverid"=>"localhost", "lis_person_name_full"=>"Sakai Administrator", "resource_link_title"=>"Attendance", "ext_sakai_session"=>"9eabbbae9757eacb5a21e928f9413a4f814edb16491bba46c20c2574d1a035c484a9c6d579816bf3", "context_id"=>"edad5908-7fd1-443c-a066-a3a336cfcc8e", "roles"=>"Instructor", "lis_person_name_given"=>"Sakai", "launch_presentation_locale"=>"en_US", "oauth_timestamp"=>"1372886104", "ext_basiclti_submit"=>"Press to continue to external tool."
    }
  end

  test "from_launch_params should create new site if it doesn't exist" do
    original_count = Site.count
    site = Site.from_launch_params(@params)

    assert_equal Site.count, original_count + 1
    assert_equal site.context_id, 'edad5908-7fd1-443c-a066-a3a336cfcc8e'
    assert_equal site.context_name, 'Test 101'
    assert_equal site.context_label, 'Test 101 Label'
  end

  #test "from_launch_params should create learner and instructor roles if they don't exist" do
  #TODO: update this test to ensure siteroles are all present after pulling the roster
  #  site = Site.from_launch_params(@params)
  #
  #  assert_equal site.siteroles.count, 2
  #  assert site.siteroles.find_by_role_id(roles(:learner).id)
  #  assert site.siteroles.find_by_role_id(roles(:instructor).id) 
  #end

  test "from_launch_params should update existing site to match params" do
    Site.from_launch_params(@params)
    @params['context_title'] = 'A different title'
    @params['context_label'] = 'A different label'
    site = Site.from_launch_params(@params)

    assert_equal site.context_id, 'edad5908-7fd1-443c-a066-a3a336cfcc8e'
    assert_equal site.context_name, 'A different title'
    assert_equal site.context_label, 'A different label' 
  end
end

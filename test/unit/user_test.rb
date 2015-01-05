require 'test_helper'
require 'libxml'

class UserTest < ActiveSupport::TestCase
  setup do
    @params = {
      "launch_presentation_css_url"=>"http://chriss-mac-pro.its.txstate.edu:8080/library/skin/default/tool.css", "ext_lms"=>"sakai2", "ext_sakai_server"=>"http://chriss-mac-pro.its.txstate.edu:8080", "oauth_nonce"=>"1372886104320318000", "oauth_consumer_key"=>"tracs.txstate.edu", "context_label"=>"Test 101 Label", "ext_ims_lis_memberships_url"=>"http://chriss-mac-pro.its.txstate.edu:8080/imsblis/service/", "lis_person_name_family"=>"Administrator", "resource_link_id"=>"914d63b6-0929-4cf3-8fc1-2ece233406b3", "oauth_callback"=>"about:blank", "oauth_signature"=>"F1WEqM+pTvjGX4A0daf6K8qAVRo=", "lti_version"=>"LTI-1p0", "oauth_signature_method"=>"HMAC-SHA1", "lti_message_type"=>"basic-lti-launch-request", "user_id"=>"admin", "user_image"=>"http://chriss-mac-pro.its.txstate.edu:8080/direct/profile/admin/image", "resource_link_description"=>"Attendance", "context_title"=>"Test 101", "oauth_version"=>"1.0", "ext_ims_lis_memberships_id"=>"eb5d7d956292d791864dfb4de9867f07c2bfc297174da68a13cbf5d2a1f21bc9:::admin:::914d63b6-0929-4cf3-8fc1-2ece233406b3", "lis_person_sourcedid"=>"admin", "context_type"=>"CourseSection", "ext_sakai_serverid"=>"localhost", "lis_person_name_full"=>"Sakai Administrator", "resource_link_title"=>"Attendance", "ext_sakai_session"=>"9eabbbae9757eacb5a21e928f9413a4f814edb16491bba46c20c2574d1a035c484a9c6d579816bf3", "context_id"=>"edad5908-7fd1-443c-a066-a3a336cfcc8e", "roles"=>"Instructor", "lis_person_name_given"=>"Sakai", "launch_presentation_locale"=>"en_US", "oauth_timestamp"=>"1372886104", "ext_basiclti_submit"=>"Press to continue to external tool."
    }

    rosterxml = "<member>" + 
                  "<lis_result_sourcedid>7d69999997</lis_result_sourcedid>" +
                  "<person_contact_email_primary>test@test.com</person_contact_email_primary>" +
                  "<person_name_family>User</person_name_family>" +
                  "<person_name_full>Test User</person_name_full>" +
                  "<person_name_given>Test</person_name_given>" +
                  "<person_sourcedid>test</person_sourcedid>" +
                  "<role>Instructor</role>" +
                  "<user_id>422e099999-45dc-a4e5-196d3f749782</user_id>" +
                "</member>"
                
    document = LibXML::XML::Parser.string(rosterxml).parse
    @xmlnode = document.find_first('/member')
    @site = Site.create(context_id: 'asdf', context_name: 'Test Course', context_label: 'Test')
    @section = @site.sections.build(:name => 'default')
    @roles = {roles(:learner).id => roles(:learner), roles(:instructor).id => roles(:instructor)}
    @sections = [@section]
  end

  test "from_launch_params should create new user if it doesn't exist" do
    original_count = User.count
    user = User.from_launch_params(@params)

    assert_equal User.count, original_count + 1
    assert_equal user.firstname, 'Sakai'
    assert_equal user.lastname, 'Administrator'
    assert_equal user.fullname, 'Sakai Administrator'
    assert_equal user.netid, 'admin'
    assert_equal user.tc_user_id, 'admin'
  end

  test "from_roster_xml should create new user if it doesn't exist" do
    original_count = User.count
    user = User.from_roster_xml(@xmlnode)

    assert_equal User.count, original_count + 1
    assert_equal user.firstname, 'Test'
    assert_equal user.lastname, 'User'
    assert_equal user.fullname, 'Test User'
    assert_equal user.netid, 'test'
    assert_equal user.tc_user_id, '422e099999-45dc-a4e5-196d3f749782'
  end

  test "verify_membership should create new membership if none exist" do
    user = User.from_launch_params(@params)
    membership = user.verify_membership(@site, @roles, true, @sections, user.memberships.find_by_site_id(@site.id))

    assert_equal user.memberships.count, 1
    assert_equal membership.site_id, @site.id
    assert_equal membership.siteroles.count, 2
  end

  test "verify_membership should do nothing if one exists" do
    user = User.from_launch_params(@params)
    user.verify_membership(@site, @roles, true, @sections, user.memberships.find_by_site_id(@site.id))
    user.verify_membership(@site, @roles, true, @sections, user.memberships.find_by_site_id(@site.id))

    assert_equal user.memberships.count, 1
  end

  test "verify_membership should change siteroles if they're different" do
    user = User.from_launch_params(@params)
    user.verify_membership(@site, @roles, true, @sections, user.memberships.find_by_site_id(@site.id))

    @roles.delete(roles(:instructor).id)
    membership = user.verify_membership(@site, @roles, true, @sections, user.memberships.find_by_site_id(@site.id))

    assert_equal membership.siteroles.count, 1
    assert_equal membership.siteroles.first.role_id, roles(:learner).id

  end
end

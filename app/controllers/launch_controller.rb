require 'digest/md5'
require 'ims/lti'
require 'oauth/request_proxy/rack_request'
require 'securerandom'
require 'libxml'

class LaunchController < ApplicationController
  skip_before_filter :verify_authenticity_token
  include UsersHelper

  def fetchRoster?
    return @site.roster_fetched_at < 1.day.ago if params[:ext_sakai_roster_hash].to_s == ''
    return params[:ext_sakai_roster_hash] != @site.roster_hash
  end

  def index
    @site = Site.from_launch_params(params)
    user = User.from_launch_params(params)
    session[:user_id] = user.id
    session[:site_id] = @site.id

    should_fetch_roster = fetchRoster?
    if params[:custom_canvas_course_id].nil?
      roles = Role.getRolesFromString(params['roles'])
      sections = @site.getSectionsFromString(params[:ext_sakai_provider_ids])
      membership = user.verify_membership(@site, roles, true, sections, user.memberships.find_by_site_id(@site.id), params['lis_result_sourcedid'])
      should_fetch_roster = false unless membership.take_attendance?
    else
      membership = @site.memberships.find_by_user_id(user.id)
      should_fetch_roster = true if membership.nil?
    end

    if should_fetch_roster
      session[:ext_ims_lis_memberships_url] = params[:ext_ims_lis_memberships_url]
      session[:ext_ims_lis_memberships_id] = params[:ext_ims_lis_memberships_id]
      session[:custom_canvas_course_id] = params[:custom_canvas_course_id]
      session[:ext_sakai_roster_hash] = params[:ext_sakai_roster_hash]
      redirect_to controller: 'rosterupdate', action: 'index', siteid: @site.id and return
    end
    redirect_to intro_page_for_site(@site, user)
  end

private
  def sanitize_sql(*sql_array)
    ActiveRecord::Base.send(:sanitize_sql_array, sql_array)
  end

  def authorize
    # Since we're only supporting one oauth consumer (the LMS) at this time, we ignore the consumer key.
    # This may change in the future if there's a need for multiple systems to connect to the same attendance instance.
    @toolprovider = IMS::LTI::ToolProvider.new("", Attendance::Application.config.oauth_secret, params)

    return authorize_fail unless @toolprovider.valid_request?(request)

    # Request shouldn't be older than 5 minutes
    return authorize_fail if @toolprovider.request_oauth_timestamp.to_i < 5.minutes.ago.to_i

    # Add nonce to db or error if it already exists
    conn = ActiveRecord::Base.connection
    return authorize_fail if conn.select_one(sanitize_sql('select * from nonces where nonce=?', @toolprovider.request_oauth_nonce))

    conn.insert(
      sanitize_sql('insert into nonces (nonce, request_time) values(?,?)',
                   @toolprovider.request_oauth_nonce,
                   @toolprovider.request_oauth_timestamp.to_i)
    )
    true
  end
end

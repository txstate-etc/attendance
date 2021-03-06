class RosterupdateController < ApplicationController
  include UsersHelper
  def index
    @siteid = params[:siteid]
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def fetchRoster?
    return false if session[:ext_ims_lis_memberships_url].to_s.empty? || session[:ext_ims_lis_memberships_id].to_s.empty?
    return @site.roster_fetched_at < 1.day.ago if session[:ext_sakai_roster_hash].to_s.empty?
    return session[:ext_sakai_roster_hash] != @site.roster_hash
  end

  def create
    @site = Site.find(params[:siteid])
    render text: intro_page_for_site(@site, User.find(session[:user_id])) and return if !fetchRoster?
    count = Site.where('id=? and (update_in_progress is NULL or update_in_progress < ?)', @site.id, 10.minutes.ago).update_all(update_in_progress: Time.zone.now)

    # If update is in progress, check every half second to see if it's finished. Repeat up to 10 times before sending response.
    respond_to do |format|
      format.html { 
        10.times do
          render text: intro_page_for_site(@site, User.find(session[:user_id])) and return if Site.where('id=? and update_in_progress is NULL', params[:siteid]).first
          sleep 0.5
        end
        head :no_content
      }
    end and return if count == 0

    10.times do
      if (parse_roster_xml get_roster_data) || @site.roster_fetched_at > 1.year.ago
        break
      else
        sleep 0.5
      end
    end
    session.delete(:ext_ims_lis_memberships_url)
    session.delete(:ext_ims_lis_memberships_id)
    session.delete(:ext_sakai_roster_hash)
    Site.where(id: @site.id).update_all(update_in_progress: nil)
    respond_to do |format|
      format.html { render text: intro_page_for_site(@site, User.find(session[:user_id])) }
    end
  end

  def get_roster_data
    uri = URI(session[:ext_ims_lis_memberships_url])

    request_params = {
      'id' => session[:ext_ims_lis_memberships_id],
      'lti_message_type' => 'basic-lis-readmembershipsforcontext',
      'lti_version' => 'LTI-1p0',
      'oauth_callback' => 'about:blank'
    }

    options = {
      :scheme => 'body',
      :timestamp => Time.now.utc.to_i,
      :nonce => SecureRandom.hex
    }

    host = uri.port == uri.default_port ? uri.host : "#{uri.host}:#{uri.port}"
    consumer = OAuth::Consumer.new(
      "notused", 
      Attendance::Application.config.oauth_secret, 
      { 
        site: "#{uri.scheme}://#{host}",
        signature_method: "HMAC-SHA1" 
      }
    )
    consumer.http.read_timeout = 120

    roster_response = consumer.request(:post, uri.path, nil, options, request_params)
    roster_response.body
  end

  def parse_roster_xml(rosterxml)
    Rosterupdate.log(@site, rosterxml)
    
    begin
      document = LibXML::XML::Parser.string(rosterxml).parse
    rescue => exception
      return false
    end

    if document.find('/message_response/statusinfo/codemajor').first.content.downcase != 'success'
      return false
    end

    site_users = {}
    @site.users.each {|user| site_users[user.tc_user_id] = user }
    users = {}
    all_sections = {}

    document.find('/message_response/members/member').each do |member|
      user = User.from_roster_xml(member, site_users[member.find_first('user_id').content])
      user_info = {}
      user_info["user"] = user

      role_node = member.find_first('roles') || member.find_first('role') #LTI spec says roles, but some sakai versions use role
      user_info["roles"] = role_node ? Role.getRolesFromString(role_node.content) : {}

      active_node = member.find_first('membership_is_active')
      user_info["active"] = !(active_node && active_node.content == 'false')
      sections_node = member.find_first('provider_ids')

      sections_string = sections_node ? sections_node.content : ""
      user_info["sections"] = sections_string
      sections_string.split(/(?<!\/)\+|,/).map { |s| s.strip.gsub('/+', '+') }.each do |section_name|
        all_sections[section_name] = [] if !all_sections.has_key?(section_name)
        all_sections[section_name].push(user.id)
      end

      sourcedid_node = member.find_first('lis_result_sourcedid')
      user_info["sourcedid"] = sourcedid_node.content if sourcedid_node
      
      users[user.id] = user_info
    end
    
    # cache away our memberships for each user for use in user.verify_membership
    Membership.where(:user_id => users.values.map{|uinfo| uinfo['user'].id}, :site_id => @site.id).each do |membership|
      users[membership.user_id]["membership"] = membership
    end
    eager_load(users.values.map{|uinfo| uinfo['membership']}, [:sections, :siteroles])

    # A section's users_hash is the md5 hash of the sorted, comma-separated list of the section's user_ids
    section_md5s = {}
    all_sections.each do |section_name, user_list|
      section_md5s[section_name] = Digest::MD5.hexdigest(user_list.sort.inject('') { |acc, user_id| acc + user_id.to_s + ',' })
    end

    # If an existing section is not in the roster data, check if it should be renamed
    # A missing section should be renamed if there is a new section in the roster with the same users as the missing section
    @site.sections.select { |section| !section.is_default && !all_sections.has_key?(section.name) }.each do |section|
      if new_section = section_md5s.find { |section_name, md5| section.users_hash == md5 && @site.sections.find_by_name(section_name).nil? }
        section.name = new_section.first
        section.save
      end
    end

    # Update users_hash for sections in the roster data
    section_md5s.each do |section_name, md5|
      section = @site.sections.find_or_create_by_name(section_name)
      section.users_hash = md5
      section.save
    end
    
    # Verify user memberships
    users.each do |user_id, user_info|
      sections = @site.getSectionsFromString(user_info["sections"])
      user_info["user"].verify_membership(@site, user_info["roles"], user_info["active"], sections, user_info["membership"], user_info["sourcedid"])
    end

    # Set users as inactive if they are in the site, but not the roster data
    @site.memberships.each do |membership|
      if users[membership.user_id].nil? && membership.active
        membership.active = false
        membership.save
      end
    end

    @site.roster_fetched_at = Time.zone.now
    @site.roster_hash = session[:ext_sakai_roster_hash]
    @site.save
  end

  private
    def authorize
      site_id = params[:siteid].to_i
      return super do
        site_id == session[:site_id] && @auth_user.take_attendance?(site_id)
      end
    end
end

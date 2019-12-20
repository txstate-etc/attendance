class RosterupdateController < ApplicationController
  include UsersHelper
  def index
    @siteid = params[:siteid]
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def create
    @site = Site.find(params[:siteid])
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
      if (save_roster_data) || @site.roster_fetched_at > 1.year.ago
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

  def save_roster_data
    if @site.is_canvas
      canvas_get_roster_data
    else
      get_roster_data
    end
  end

  def teacherrole
    @allroles ||= Role.all
    @teacherrole ||= @allroles.find {|r| r.roletype == 'Instructor'}
  end
  def studentrole
    @allroles ||= Role.all
    @studentrole ||= @allroles.find {|r| r.roletype == 'Learner'}
  end
  def tarole
    @allroles ||= Role.all
    @tarole ||= @allroles.find {|r| r.roletype == 'TeachingAssistant'}
  end
  def graderrole
    @allroles ||= Role.all
    @graderrole ||= @allroles.find {|r| r.roletype == 'TeachingAssistant/Grader'}
  end
  def observerrole
    @allroles ||= Role.all
    @observerrole ||= @allroles.find {|r| r.roletype == 'Instructor/ExternalInstructor'}
  end

  def canvas_get_roster_data
    sections = Canvas.getall("/v1/courses/#{session[:custom_canvas_course_id]}/sections")
    sectionsByLmsId = sections.reduce({}) do |sectionsByLmsId, section|
      dbsection = @site.sections.find_or_create_by_lms_id(section[:id])
      dbsection.name = section[:sis_section_id] || ''
      dbsection.display_name = section[:name]
      dbsection.save
      sectionsByLmsId[dbsection.lms_id] = dbsection
      sectionsByLmsId
    end

    enrollments = Canvas.getall("/v1/courses/#{session[:custom_canvas_course_id]}/enrollments")
    netids = enrollments.map {|e| User.netidfromshibb(e[:user][:login_id])}
    users = User.where(:netid => netids)
    userHash = users.reduce({}) do |userHash, user|
      userHash[user.netid] = user
      userHash
    end
    eager_load(@site, {:memberships => [:sections, :siteroles]})
    valid_users = {}
    enrollments.each do |enrollment|
      netid = User.netidfromshibb(enrollment[:user][:login_id])
      user = User.from_canvas_api(netid, enrollment, userHash[netid])
      membership = @site.memberships.find {|m| m.user_id == user.id}
      role = teacherrole if enrollment[:type] == 'TeacherEnrollment'
      role = tarole if enrollment[:type] == 'TeacherEnrollment'
      role = observerrole if enrollment[:type] == 'ObserverEnrollment'
      role = observerrole if enrollment[:type] == 'DesignerEnrollment'
      role = studentrole if enrollment[:type] == 'StudentEnrollment'
      role = graderrole if enrollment[:role] == 'Grader'
      next if role.nil?
      valid_users[user.id] = true
      verifiedmembership = user.verify_membership(@site, {role.id => role}, enrollment[:enrollment_state] == 'active', sectionsByLmsId[enrollment[:course_section_id]], membership)
      @site.memberships.push(verifiedmembership) if membership.nil?
    end
    @site.memberships.each do |membership|
      if valid_users[membership.user_id].nil? && membership.active
        membership.active = false
        membership.save
      end
    end
    #Gradeupdate.register_site_change(@site) if @site.outcomes_url.blank? && !@site.assignment_id.nil?
    #@site.outcomes_url = @site.assignment_id
    @site.roster_fetched_at = Time.zone.now
    @site.save
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
        site_id == session[:site_id] && (@auth_user.take_attendance?(site_id) || !session[:custom_canvas_course_id].nil?)
      end
    end
end

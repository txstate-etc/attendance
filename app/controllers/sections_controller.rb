class SectionsController < ApplicationController
  # GET /sections
  # GET /sections.json
  def index
    @sections = Section.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sections }
    end
  end

  # GET /sections/1
  # GET /sections/1.json
  def show
    @section ||= Section.find(params[:id])
    if request.format.csv?
      opts = {
        sessions: params[:sessions] == 'true',
        checkins: params[:checkins] == 'true',
        totals: params[:totals] == 'true'
      }
      csvdump = @section.export_to_csv(opts)
      response.headers['Cache-Control'] = 'no-cache'
      send_data(
          csvdump,
          :filename => @section.site.safe_context_name + '_' + @section.safe_name + '_attendance_' + Time.zone.now.strftime("%Y%m%d") + '.csv',
          :type => 'text/csv',
          :disposition => 'attachment'
      )
      return
    end

    @meetings = @section.meetings.includes(:userattendances).order("starttime DESC").to_a
    @memberships = @section.site.memberships.includes(:user, :siteroles).index_by(&:id)
    eager_load(@memberships.values, :sections, :conditions => ["sections.id=?", @section.id])
    @attendancetypes = Attendancetype.getall

    @attendances = {}
    @meetings.each do |meeting|
      meeting.userattendances.each do |ua|
        ua.cache_membership(@memberships)
        next if !ua.membership.record_attendance?
        @attendances[ua.membership.id] ||= {}
        @attendances[ua.membership.id][meeting.id] = ua
      end
    end

    @attendances = @attendances.sort_by{|membership_id, ua_hash|
      m = ua_hash.values.first.membership
      [m.sections.include?(@section) ? 0 : 1, m.active ? 0 : 1, m.user.lastname.downcase, m.user.firstname.downcase]
    }

    uncancelled_meetings = @meetings.reject { |m| m.cancelled }

    @num_cancelled_meetings = @meetings.length - uncancelled_meetings.length
    @force_show_cancelled = uncancelled_meetings.empty?
    @show_remove_user_link = @auth_user.admin

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @section }
    end
  end

  def totals
    @section ||= Section.find(params[:id])
    @userattendances = @section.past_attendances.includes({:membership => :user}, :meeting).order('users.lastname, users.firstname')
    eager_load(@userattendances.map(&:membership), :sections, :conditions => ["sections.id=?", @section.id])

    @totals = {}
    @userattendances.each do |ua|
      atype_id = ua.attendancetype_id
      atype = Attendancetype.fetch(atype_id)
      @totals[ua.membership.id] = { :membership => ua.membership, :attendancetypes => {} } unless @totals.has_key?(ua.membership.id)
      @totals[ua.membership.id][:attendancetypes][atype_id] = { :attendancetype => atype, :total => 0, :meetings => []} unless @totals[ua.membership.id][:attendancetypes].has_key?(atype_id)
      @totals[ua.membership.id][:attendancetypes][atype_id][:total] += 1
      @totals[ua.membership.id][:attendancetypes][atype_id][:meetings].push(ua.meeting)
    end

    @moved_totals = {}
    @inactive_totals = {}
    @totals.reject! do |k,v|
      if !v[:membership].sections.include? @section
        @moved_totals[k] = v
      elsif !v[:membership].active
        @inactive_totals[k] = v
      end
      !v[:membership].active || !v[:membership].sections.include?(@section)
    end

    respond_to do |format|
      format.html # totals.html.erb
      format.json { render json: @totals }
    end
  end

  def last_dates
    if params[:site_id]
      @section = Section.joins(:site).where('sites.id=? OR sites.context_id=?', params[:site_id], params[:site_id]).where('sections.id=? OR sections.name=?', params[:id], params[:id]).first
    else
      @section = Section.find(params[:id])
    end
    ret = {}
    @section.recorded_memberships.each do |m|
      ret[m.user.netid] = m.last_attended(@section)
    end
    respond_to do |format|
      format.json { render json: ret }
      format.xml { render xml: ret }
    end
  end

  def record_attendance
    errors = []
    params.each do |name, value|
      if name =~ /meeting-(\d+)_member-(\d+)/
        errors += Userattendance.record_attendance($1, $2, value)
      end
    end
    if errors.length > 0
      if (params[:json])
        render json: errors if params[:json]
      else
        flash[:notice] = errors.length.to_s+' errors occurred while attempting to record attendance.'
        redirect_to action: 'show'
      end
    else
      if params[:json]
        render json: []
      else
        flash[:notice] = errors.length.to_s+' errors occurred while attempting to record attendance.'
        redirect_to action: 'show'
      end
    end
  end

  # GET /sections/new
  # GET /sections/new.json
  def new
    @section = Section.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @section }
    end
  end

  # GET /sections/1/edit
  def edit
    @section ||= Section.find(params[:id])
  end

  # POST /sections
  # POST /sections.json
  def create
    @section = Section.new(params[:section])

    respond_to do |format|
      if @section.save
        format.html { redirect_to @section, notice: 'Section was successfully created.' }
        format.json { render json: @section, status: :created, location: @section }
      else
        format.html { render action: "new" }
        format.json { render json: @section.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sections/1
  # PUT /sections/1.json
  def update
    @section ||= Section.find(params[:id])

    respond_to do |format|
      if @section.update_attributes(params[:section])
        format.html { redirect_to @section, notice: 'Section was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @section.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sections/1
  # DELETE /sections/1.json
  def destroy
    @section ||= Section.find(params[:id])
    @section.destroy

    respond_to do |format|
      format.html { redirect_to sections_url }
      format.json { head :no_content }
    end
  end

  # GET /sections/1/userattendances
  def userattendances
    @section ||= Section.find(params[:id])
    checkins_since = Time.at(params[:checkins_since].to_i / 1000)
    uas =  @section.userattendances
               .joins(:checkins)
               .includes(:checkins)
               .where('userattendances.updated_at > ?', checkins_since)
    render json: uas, include: :checkins
  end

  def checkin
    section = Section.find(params[:id]) rescue nil
    sections = section ? [section] : Section.includes(site: :checkinsettings).find_all_by_name(params[:id])
    sections.each do |section|
      next unless section.site.checkinsettings.auto_enabled
      startTime = Time.at(params['sessionStart'] / 1000)
      time = Time.at(params['time'] / 1000)

      head :no_content and return if (time + 15.minutes < startTime)
      meeting = section.meetings
                    .create_with(initial_atype: Attendancetype.find_by_name('Absent'), starttime: startTime)
                    .find_or_create_by_source_starttime(startTime)

      user = User.find_by_netid(params[:netid])
      head :unprocessable_entity and return if user.nil?
      membership = section.site.memberships.find_by_user_id(user.id)
      if membership.nil?
        roles = Role.getRolesFromString('urn:lti:role:ims/lis/Learner')
        membership = user.verify_membership(section.site, roles, true, [section], nil)
      end
      unless membership.sections.include?(section)
        membership.sections.push(section)
        membership.save
      end

      ua = meeting.userattendances.find_by_membership_id(membership)
      if ua.checkins.empty?
        ua.checkins.create({source: params['source'], time: time})
      end
    end

    head :no_content
  end

private
  def authorize
    if ['record_attendance', 'show', 'totals', 'edit_perms', 'update_perms', 'userattendances'].include?(action_name)
      @section ||= Section.find(params[:id])
      site_id = @section.site.id
    end
    return super do
      site_id == session[:site_id] && @auth_user.take_attendance?(site_id)
    end if ['record_attendance', 'show', 'totals', 'userattendances'].include?(action_name)
    return true if 'checkin' == action_name && request.authorization == Attendance::Application.config.checkin_token
    return super
  end

  def print_totals_hash_to_csv(totals_hash, csv)
    totals_hash.each do |membership_id, record|
      rec = [record[:membership].user.fullname]
      Attendancetype.getall.each do |atype|
        rec.push((record[:attendancetypes][atype.id][:total] rescue 0))
      end
      csv << rec
    end
  end
end

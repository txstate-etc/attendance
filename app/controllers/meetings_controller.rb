class MeetingsController < ApplicationController
  # GET /meetings
  # GET /meetings.json
  def index
    @meetings = Meeting.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @meetings }
    end
  end
  
  def record_attendance
    errors = []
    params.each do |name, value|
      if name =~ /member-(\d+)/
        errors += Userattendance.record_attendance(params[:id], $1, value)
      end
    end
    if errors.length > 0
      if params[:json]
        render json: errors
      else
        flash[:notice] = errors.length.to_s+' errors occurred while attempting to record attendance.'
        redirect_to action: 'edit'
      end
    else 
      if params[:json]
        render json: []
      else
        flash[:notice] = 'Attendance for all students successfully recorded.'
        redirect_to action: 'edit'
      end
    end
  end

  # GET /sections/:section_id/meetings/new
  # GET /sections/:section_id/meetings/new.json
  def new
    @section ||= Section.find(params[:section_id])
    @meeting = @section.meetings.new
    @meeting.starttime = Time.now
    @attendancetypes = Attendancetype.getall

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @meeting }
    end
  end

  # GET /meetings/1/edit
  def edit
    @meeting ||= Meeting.find(params[:id])
    @userattendances = @meeting.userattendances.includes(:membership => [:user, :siteroles]).order('users.lastname').to_a
    @attendancetypes = Attendancetype.getall

    @userattendances = @userattendances.sort_by{|ua|
      m = ua.membership
      [m.sections.include?(@meeting.section) ? 0 : 1, m.active ? 0 : 1, m.user.lastname.downcase, m.user.firstname.downcase]
    }
  end

  # POST /sections/:section_id/meetings
  # POST /sections/:section_id/meetings.json
  def create
    @section ||= Section.find(params[:section_id])
    @meeting = @section.meetings.new

    begin
      @meeting.starttime = Time.parse(params["meeting_startdate"] + ' ' + params["meeting_starttime"])
    rescue ArgumentError => e
      @meeting.starttime = Time.now
      @meeting.errors.add(:starttime, 'Invalid date format.')
      render action: "new" and return
    end

    @meeting.initial_atype = Attendancetype.find(params["initial_atype"])
    @meeting.checkin_code = generate_code if params['generate_code']

    respond_to do |format|
      if @meeting.save
        format.html { redirect_to @section }
        format.json { render json: @meeting, status: :created, location: @meeting }
      else
        format.html { render action: "new" }
        format.json { render json: @meeting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /meetings/1
  # PUT /meetings/1.json
  def update
    @meeting ||= Meeting.find(params[:id])

    begin
      if params["meeting_startdate"] && params["meeting_starttime"]
        @meeting.starttime = Time.parse(params["meeting_startdate"] + ' ' + params["meeting_starttime"])
      end
    rescue ArgumentError => e
      @meeting.errors.add(:starttime, 'Invalid date format.')
      render action: "edit" and return
    end

    respond_to do |format|
      if @meeting.update_attributes(params[:meeting])
        format.html {
          if params[:meeting][:cancelled] == "true" || params[:meeting][:deleted] == "true"
            redirect_to @meeting.section
          else
            flash[:notice] = 'Start date/time updated successfully'
            redirect_to action: "edit"
          end
        }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @meeting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /meetings/1
  # DELETE /meetings/1.json
  def destroy
    @meeting ||= Meeting.find(params[:id])
    @meeting.destroy

    respond_to do |format|
      format.html { redirect_to meetings_url }
      format.json { head :no_content }
    end
  end

  def code
    @meeting ||= Meeting.find(params[:id])
    if params[:remove] == '1'
      @meeting.checkin_code = nil
    else
      @meeting.checkin_code = generate_code
    end

    if @meeting.save
      render json: @meeting, status: 200
    else
      render json: @meeting.errors, status: :unprocessable_entity
    end
  end

private
  def authorize
    return super do
      site_id = (@meeting = Meeting.find(params[:id])).section.site.id
      site_id == session[:site_id] && @auth_user.take_attendance?(site_id)
    end if ['record_attendance', 'edit', 'update', 'destroy', 'code'].include?(action_name)
    return super do
      site_id = Section.find(params[:section_id]).site.id
      site_id == session[:site_id] && @auth_user.take_attendance?(site_id)
    end if ['new', 'create'].include?(action_name)
    return super
  end

  def generate_code
    (0..5).map{[*'a'..'z',*1..9].sample}.join
  end
end

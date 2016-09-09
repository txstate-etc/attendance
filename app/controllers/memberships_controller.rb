class MembershipsController < ApplicationController
  # GET /memberships
  # GET /memberships.json
  def index
    @memberships = Membership.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @memberships }
    end
  end

  # GET /memberships/1
  # GET /memberships/1.json
  def show
    @membership ||= Membership.find(params[:id])
    @section = Section.find(params[:section_id])
    @attendancetypes = Attendancetype.getall
    @show_back = (@auth_user && @auth_user.take_attendance?(@section.site)) || request.referrer.include?('enter_code')
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @membership }
    end
  end

  # GET /memberships/new
  # GET /memberships/new.json
  def new
    @membership = Membership.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @membership }
    end
  end

  # GET /memberships/1/edit
  def edit
    @membership ||= Membership.find(params[:id])
  end

  # POST /sections/1/memberships/1/remove_from_section
  def remove_from_section
    @membership ||= Membership.find(params[:membership_id])
    section ||= Section.find(params[:section_id])
    @membership.remove_from_section(section)
    redirect_to section, notice: 'User was successfully removed.'
  end

  # POST /memberships
  # POST /memberships.json
  def create
    @membership = Membership.new(params[:membership])

    respond_to do |format|
      if @membership.save
        format.html { redirect_to @membership, notice: 'Membership was successfully created.' }
        format.json { render json: @membership, status: :created, location: @membership }
      else
        format.html { render action: "new" }
        format.json { render json: @membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /memberships/1
  # PUT /memberships/1.json
  def update
    @membership ||= Membership.find(params[:id])

    respond_to do |format|
      if @membership.update_attributes(params[:membership])
        format.html { redirect_to @membership, notice: 'Membership was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /memberships/1
  # DELETE /memberships/1.json
  def destroy
    @membership ||= Membership.find(params[:id])
    @membership.destroy

    respond_to do |format|
      format.html { redirect_to memberships_url }
      format.json { head :no_content }
    end
  end

private
  def authorize
    return super do
      @membership ||= Membership.find(params[:id])
      site_id = @membership.site.id
      site_id == session[:site_id] && (@auth_user.take_attendance?(site_id) || @auth_user.id == @membership.user.id)
    end if ['show'].include?(action_name)
    return super
  end
end

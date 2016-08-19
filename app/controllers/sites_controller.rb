class SitesController < ApplicationController
  def index
    @sites = Site.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sites }
    end
  end

  def show
    @site = Site.find(params[:id])
    @sections = @auth_user.sections_to_choose(@site).sort { |a,b| if a.is_default == b.is_default then a.name <=> b.name elsif a.is_default then 1 else -1 end }

    prepare_for_mobile
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @membership }
    end
  end

  def edit_settings
    @site ||= Site.find(params[:id])
    @multiple_sections = @site.sections.reject { |s| s.name == "Unassigned" }.count > 1
    set_return_to
    respond_to do |format|
      format.html # edit_settings.html.erb
    end
  end

  def update_settings
    @site ||= Site.find(params[:id])
    unless params['site']['gradesettings_attributes'].nil?
      params['site']['gradesettings_attributes']['deduction'] ||= 0
      params['site']['gradesettings_attributes']['tardy_per_absence'] ||= 0
      params['site']['gradesettings_attributes']['tardy_value'] ||= 100
    end
    session[:return_to] ||= request.referer
    if @site.update_attributes(params[:site])
      flash[:notice] = 'Settings were successfully updated.'
    else
      flash[:notice] = nil
    end
    render 'edit_settings'
  end
  
  def edit_perms
    @site ||= Site.find(params[:id])
    @siteroles = @site.siteroles.includes(:role).order('roles.displayorder').to_a
    set_return_to
    respond_to do |format|
      format.html # edit_perms.html.erb
    end
  end
  
  def update_perms
    @site ||= Site.find(params[:id])
    if @site.update_attributes(params[:site])
      redirect_to edit_perms_site_path(@site), notice: 'Permissions were successfully updated.'
    else
      redirect_to edit_perms_site_path(@site), notice: 'There was a problem updating permissions.'
    end
  end

  def set_return_to
    # Store referer so the back button still works after saving settings. Otherwise the
    # back button just returns to edit_settings/edit_perms.
    referer_path = URI(request.referer).path
    route = Rails.application.routes.recognize_path(referer_path) rescue nil
    return if route.nil?
    session[:return_to] = request.referer if !['edit_perms', 'update_perms', 'edit_settings', 'update_settings'].include?(route[:action])
    session[:return_to] ||= :back
  end
private
  def authorize
    return super do
      params[:id].to_i == session[:site_id].to_i
    end if ['show'].include?(action_name)
    return super do
      params[:id].to_i == session[:site_id].to_i && @auth_user.set_permissions?(params[:id])
    end if ['edit_perms', 'update_perms'].include?(action_name)
    return super do
      params[:id].to_i == session[:site_id].to_i && @auth_user.edit_gradesettings?(params[:id])
    end if ['edit_settings', 'update_settings', 'edit_checkin_settings', 'update_checkin_settings'].include?(action_name)
    return super
  end
end

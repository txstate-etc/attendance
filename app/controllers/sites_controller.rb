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
    @settings = Gradesettings.find_or_create_by_site_id(params[:id])
    @multiple_sections = @site.sections.reject { |s| s.name == "Unassigned" }.count > 1
    set_return_to
    respond_to do |format|
      format.html # edit_settings.html.erb
    end
  end

  def update_settings
    @site ||= Site.find(params[:id])
    @settings = Gradesettings.find_by_site_id(params[:id])
    session[:return_to] ||= request.referer
    tardy_value = Integer(params[:gradesettings_tardy_value]) rescue -1
    tardy_per_absence = Integer(params[:gradesettings_tardy_per_absence]) rescue -1
    forgiven_absences = Integer(params[:gradesettings_forgiven_absences]) rescue -1
    deduction = Integer(params[:gradesettings_deduction] || 0) rescue -1
    max_points = Integer(params[:gradesettings_max_points]) rescue -1
    points_type = params[:gradesettings_points_type]

    redirect_to edit_settings_site_path(@site), notice: 'Deduction per absence must be a non-negative integer between 0 and 100' and return if deduction < 0 || deduction > 100
    redirect_to edit_settings_site_path(@site), notice: 'Tardy value must be an integer between 0 and 100' and return if params[:gradesettings_tardy_per_absence].nil? && tardy_value < 0 || tardy_value > 100
    redirect_to edit_settings_site_path(@site), notice: 'Number of forgiven absences must be a non-negative integer' and return if forgiven_absences < 0
    redirect_to edit_settings_site_path(@site), notice: 'Tardy per absence must be a non-negative integer' and return if params[:gradesettings_tardy_value].nil? && tardy_per_absence < 0
    redirect_to edit_settings_site_path(@site), notice: 'Max points must be a positive integer' and return if points_type == 'free' && max_points <= 0

    auto_max_points = points_type == 'count'
    old_auto_max_points = @settings.auto_max_points
    old_max_points = @settings.max_points
    @settings.auto_max_points = auto_max_points
    @settings.max_points = max_points if !auto_max_points

    tardy_value = 100 if tardy_value == -1
    tardy_per_absence = 0 if tardy_per_absence == -1

    @settings.tardy_value = tardy_value / 100.0
    @settings.forgiven_absences = forgiven_absences
    @settings.deduction = deduction / 100.0
    @settings.tardy_per_absence = tardy_per_absence

    if old_max_points != max_points || auto_max_points != old_auto_max_points || auto_max_points
      success = Gradeupdate.update_max_points(@settings)
      redirect_to edit_settings_site_path(@site), notice: 'Failed to update max points, please try again later' and return if !success
    end

    if @settings.save
      redirect_to edit_settings_site_path(@site), notice: 'Settings were successfully updated.'
    else
      redirect_to edit_settings_site_path(@site), notice: 'There was a problem updating settings.'
    end
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
    end if ['edit_settings', 'update_settings'].include?(action_name)
    return super
  end
end

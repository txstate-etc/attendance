class ApplicationController < ActionController::Base
  protect_from_forgery
  prepend_before_filter :cas_setup
  before_filter :load_user
  before_filter :authorize
  before_filter :check_for_mobile
  before_filter :set_locale

  ##### CAS AUTHENTICATION #####
  # for admin screens
  def cas_setup
    RubyCAS::Filter.config[:service_url] = url_for :login
  end

  def cas_require
    session[:cas_redirect] = request.url
    if RubyCAS::Filter.filter(self)
      @auth_user = User.bynetid(session[:cas_user])
      session[:user_id] = @auth_user.id
      session[:site_id] = nil
      return true
    end
    false
  end

  ##### LTI AUTHENTICATION #####
  # most of the LTI stuff happens in the launch_controller
  def load_user
    @auth_user ||= User.find(session[:user_id]) unless session[:user_id].nil?
  end

  ##### AUTHORIZATION #####
  # authorization will always pass if the user is marked as a server admin
  def authorize

    # this authorization method should ONLY be used over SSL, otherwise the key
    # is out in the wild for the taking
    # TODO: OAuth or something similar
    return true if api_read? && params[:sharedkey] == Attendance::Application.config.oauth_secret

    return authorize_fail if @auth_user.nil?
    return true if @auth_user.admin
    return authorize_fail unless block_given?
    return authorize_fail unless yield
    return true
  end

  # renders an error message after a failed authorization
  # returns false so that the authorize filter can return false, thus
  # halting execution
  def authorize_fail
    if request.format == :json
      render :text => "Unauthorized action."
    else
      render :file => "static/401", :formats => [:html], :status => :unauthorized
    end
    return false
  end

  def api_read?
    (request.format == :json || request.format == :xml) && request.get?
  end

  def eager_load(records, associations, options = {})
    ActiveRecord::Associations::Preloader.new(records, associations, options).run
  end

  def check_for_mobile
    session[:mobile_override] = params[:mobile] if params[:mobile]
    prepare_for_mobile if use_mobile_template?
  end

  def prepare_for_mobile
    prepend_view_path Rails.root.join('app','templates','mobile','views')
  end

  def use_mobile_template?
    return true if session[:mobile_override] == '1'
    return false if session[:mobile_override] == '0'
    mobile_device?
  end
  helper_method :use_mobile_template?

  def mobile_device?
    (request.user_agent =~ /ipod|iphone|android.*mobile|opera mini|blackberry|pre\/|palm os/i) ||
    (request.user_agent =~ /palm|hiptop|avantgo|fennec|plucker|xiino|blazer|elaine/i) ||
    (request.user_agent =~ /iris|3g_t|windows ce|opera mobi|windows ce; smartphone;/i) ||
    (request.user_agent =~ /windows ce; iemobile|SymbianOS|NetFront|Teleca|PlayStation Portable/i)
  end
  helper_method :mobile_device?

  def set_locale
    I18n.locale = params[:locale] || params[:launch_presentation_locale] || I18n.default_locale
  end

  def default_url_options(options = {})
    { locale: I18n.locale }.merge options
  end

  def canvas_req(path)
    if @http.nil?
      @http = HTTPClient.new
      @http.connect_timeout = 5
      @http.receive_timeout = 5
      @http.send_timeout = 5
    end

    logger.info('fetching from canvas ' + Attendance::Application.config.canvas_api_base + path)
    logger.info('bearer token ' + Attendance::Application.config.canvas_api_token)
    res = @http.get(Attendance::Application.config.canvas_api_base + path, nil, { 'Authorization' => 'Bearer ' + Attendance::Application.config.canvas_api_token })
    return JSON.parse(res.content, :symbolize_names => true) rescue {}
  end

  def canvas_lti(path)
    uri = URI(Attendance::Application.config.canvas_api_base + '/lti' + path)
    logger.info(uri.path)

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

    response = consumer.request(:get, uri.path, nil, options)
    logger.info(response.body)
    return JSON.parse(response.body, :symbolize_names => true) rescue {}
  end
end

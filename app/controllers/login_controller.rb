class LoginController < ApplicationController
  before_filter RubyCAS::Filter
  skip_before_filter :verify_authenticity_token
  skip_before_filter :authorize
  
  def index
    if session[:cas_user] then
      session[:cas_redirect] ||= root_url
      redirect_to session[:cas_redirect]
    end
  end

end

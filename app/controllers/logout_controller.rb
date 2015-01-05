class LogoutController < ApplicationController
  
  def index
    if session[:cas_user] then
      RubyCAS::Filter.logout(self, root_url)
    else
      redirect_to root_url
    end
  end

end
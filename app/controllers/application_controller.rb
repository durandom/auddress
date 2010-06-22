# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Gettext is out for now, we'll use official i18n from rails
  #init_gettext "audress"
  # just return the string. until we have some propper i18n
  def _(s)
    s
  end

  def n_(s)
    s
  end



  # AuthenticatedSystem must be included for RoleRequirement, and is provided by installing acts_as_authenticates and running 'script/generate authenticated account user'.
  include AuthenticatedSystem
  # You can move this into a different controller, if you wish.  This module gives you the require_role helpers, and others.
  include RoleRequirementSystem

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '3b5ac63498a4bb0175be9bdcc0de402f'

  #FIXME why do I have to do this? Calling from view is not enough?
  # I only do this, to have @current_user set to non nil
  #before_filter :check_logged_in
  
  def rescue_action_in_public(exception)
    flash[:warning] = "Global Exception Handler rescued us!!  #{exception} "
    redirect_to('/')
  end
  def local_request?
    false
  end
  
  protected
  #def check_logged_in
  #  if (logged_in?)
  #    # also assign @user
  #    #@user = @current_user
  #  end
  #end
end

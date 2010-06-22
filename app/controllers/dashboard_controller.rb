class DashboardController < ApplicationController
  before_filter :login_required

  def index
    # find some link requests
    @link_requests = LinkRequest.find_requests_for_user(current_user)
  end
end

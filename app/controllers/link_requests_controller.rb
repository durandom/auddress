class LinkRequestsController < ApplicationController
  before_filter :login_required

  def create
    # FIXME ensure person belongs to current_user
    link_not_requested = false
    if LinkRequest.find_by_person_id_and_user_id(params[:person_id],current_user.id).nil?
      @link_request = LinkRequest.new
      @link_request.person = Person.find(params[:person_id])
      @link_request.user   = current_user
      link_not_requested = true
    end      

    respond_to do |format|
      if link_not_requested and @link_request.save
        flash[:notice] = _('LinkRequest was successfully created.')
        format.js   { render :partial => 'created'}
      else
        # FIXME: what to do on error
        format.html { render :action => "new" }
      end
    end
  end

  def accept
    @link_request = LinkRequest.find(params[:id])
    # FIXME: assert current_user == requested_user
    respond_to do |format|
      if @link_request.accept
        format.js   { render :partial => 'accepted', 
          :locals => { :link_request => @link_request }
        }
      else
        # FIXME: what to do on error
      end
    end
  end
  
  def reject
    @link_request = LinkRequest.find(params[:id])
    # FIXME: assert current_user == requested_user
    respond_to do |format|
      if @link_request.reject
        format.js   { render :partial => 'rejected', 
          :locals => { :link_request => @link_request   }
        }
      else
        # FIXME: what to do on error
      end
    end    
  end
  
end

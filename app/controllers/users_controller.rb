class UsersController < ApplicationController
  
  before_filter :not_logged_in_required, :only => [:new, :create] 
  before_filter :login_required, :only => [:show, :edit, :update]
  before_filter :set_user, :only => [:show, :edit, :update]
  
  def set_user
    @user = @current_user
    @person = @current_user.person
  end
  
  # render new.rhtml
  def new
    if params[:token]
      @invitation = Invitation.find_by_token(params[:token])
      session[:invitation] = @invitation.id
    end
    render :layout => 'sessions'
    # remove invitation from session
    #  session[:invitation] = nil
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    
    @user = User.new(params[:user])
    @user.save
    
    if @user.errors.empty?
      self.current_user = @user
      #render :action => 'edit'
      flash[:notice] = _('Thanks for joining!')
      if session[:invitation]
        # copy personal data from invitation
        # FIXME: make sure the invitation has not been used/activated before
        invitation = Invitation.find(session[:invitation])
        new_person = invitation.person.clone_deep
        new_person.user = @user       
        @user.person = new_person
        @user.save

        # assign the new user to the invitation
        invitation.invited_user = @user        
        # invalidate token
        invitation.token = ''
        invitation.save

        # attach user to any link requests
        if lr = LinkRequest.find_by_invitation_id(invitation.id)
          lr.requested_user ||= @user
          lr.save
        end

        #remove invitation id from session
        session[:invitation] = nil
      end
      # also add the person to the users book
      @user.person.save
      @user.book.people << @user.person

      # also create the vcard sync source
      sync_source = SyncSourceVcard.new(:user => @user)
      sync_source.save

      # FIXME: only redirect back to a location other than signup
      #   signup causes a loop, because we are logged in now, but signup requires
      #   not logged in user...
      # redirect_back_or_default('/')
      redirect_to :controller => 'users', :action => 'personal_data' # root_url
    else
      #
      @invitation = Invitation.find(session[:invitation]) if session[:invitation]
      render :action => 'new', :layout => 'sessions'
    end
  end
  
  def personal_data
    respond_to do |format|
      format.html { render :action => "edit" }
    end
  end
  
  def show
    # find some link requests
    @link_requests = LinkRequest.find_requests_for_user(current_user)
    # check if there are conflicts
    SyncSource.find_all_by_user_id(current_user).each do |ss|
      break if @conflicts = !ss.sync_items.conflict.empty?
    end
    @duplicate_count = current_user.book.people.duplicates.count

    @person = current_user.person

  end
  
  def edit
    # @user is edited, set by logged_in?
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @person }
      format.js   { render :partial => 'form'}
    end
  end

  def edit_person
    @person = current_user.person
    flash[:edit_user_person] = 1
    respond_to do |format|
      format.html { render :partial => 'people/form'}
    end
  end
  
  def update
    # we dont find by id, @user is set by application.rb
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = _('User was successfully updated.')
        format.html { redirect_to(@user) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def log
    @events = current_user.events
  end

end

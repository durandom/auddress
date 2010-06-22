class InvitationsController < ApplicationController
  # GET /invitations
  def index
    @invitations = Invitation.find(:all)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /invitations/1
  def show
    @invitation = Invitation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /invitations/new
  def new
    @invitation = Invitation.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /invitations/1/edit
  def edit
    @invitation = Invitation.find(params[:id])
  end

  # POST /invitations
  def create
    @invitation = Invitation.new(params[:invitation])

    respond_to do |format|
      if @invitation.save
        flash[:notice] = 'Invitation was successfully created.'
        format.html { redirect_to(@invitation) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /invitations/1
  def update
    @invitation = Invitation.find(params[:id])

    respond_to do |format|
      if @invitation.update_attributes(params[:invitation])
        flash[:notice] = 'Invitation was successfully updated.'
        format.html { redirect_to(@invitation) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /invitations/1
  def destroy
    @invitation = Invitation.find(params[:id])
    @invitation.destroy

    respond_to do |format|
      format.html { redirect_to(invitations_url) }
    end
  end
end

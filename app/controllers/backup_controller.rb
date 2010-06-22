class BackupController < ApplicationController

  before_filter :get_backup

  def get_backup
    ss = SyncSourceVcard.find_all_by_user_id(current_user.id).first
    @backup = Backup.new(ss)
  end

  def index
    @history = @backup.history

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def get
    if commit_id = params[:id]
      logger.warn commit_id
      a= @backup.restore(commit_id)
      b= @backup.history
      send_data(
        @backup.restore(commit_id),
        :type => 'application/vcard',
        :filename => "#{current_user.login}.vcf", # some unique filename
        :disposition => 'inline'
      )
    end
  end


end

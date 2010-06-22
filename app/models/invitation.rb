class Invitation < ActiveRecord::Base
  include TokenGenerator

  # The user who created the invitation
  belongs_to :user
  # The person to which the invitation is send
  belongs_to :person

  # After the user signs up, save the new user here
  belongs_to :invited_user, :class_name => 'User'

  before_create :set_token, :check_deliverabilty
  after_create :send_mail

  def check_deliverabilty
    # make sure we have an email to send to
    # FIXME: somehow deny the creation if no email exists...    
  end

  def emails
    person.emails.collect { |e| e.email_address_with_name }
  end

  def send_mail
    Mailer.deliver_invitation(self)
  end


  private
  def token_valid?(t)
    # FIXME: somehow lock the table until the record is saved
    #   or we might run into racing conditions when creating tokens
    !self.class.exists?(:token => t)
  end

  def set_token
    self.token = generate_token { |token| token_valid?(token) }
  end

end

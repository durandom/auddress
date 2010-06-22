class LinkRequest < ActiveRecord::Base
  # the user, which issued the request. the requestor
  belongs_to :user
  # the person for which the link request was issued, from the requestors view
  belongs_to :person
  # user corresponding to person, but from the requested persons view.
  # so it can be nil, if the user does not yet have an account
  # and it cannot be the same as :user
  belongs_to :requested_user, :class_name => "User"

  # in case we send an invitation
  belongs_to :invitation, :dependent => :destroy

  before_create :find_requested_user_for_person, :assert_user_owns_person
  
  # send the invitation afterwards, so we are sure the link_request is saved
  after_create :send_invitation
  
  # trys to find the corresponding user for the person_id
  def find_requested_user_for_person
    # make sure we have some emails to search for
    if person and person.emails
      # for every email that belongs to the person
      person.emails.each do |email|
        # try to find all corresponding emails in the global email pool
        Email.find_all_by_email(email.email).each do |candidate_email|
          # FIXME: update Email.find to use sql to exclude contacts emails in the first place
          # if this email is one of a user (and not just an contact entry)
          # and if our requestor is not the user of that email
          if candidate_email.person == candidate_email.person.user.person and
              user != candidate_email.person.user
            # its a good chance we have the requested user
            self.requested_user = candidate_email.person.user
          end          
        end
      end
    end
  end
  
  def self.find_requests_for_user(user)
    self.find_all_by_requested_user_id(user.id, :conditions => {:status => nil}) || []
  end
  
  def assert_user_owns_person
    if user != person.user
      raise Exception, "You dont own this guy" 
    end
  end
 
  def establish_link
    return false if accepted? or rejected?
    # this is the link, that the first user requested
    link_requestor = PersonLink.new(
      :source_person => requested_user.person, :person => person)
    link_requestor.save
    # for conveniance, we establish the link the other way round
    # FIXME: search through the book to find somebody that matches user.person ?
    # Or rely on the duplicate? We cant say for sure that the person is already
    #   in the book. If the request came with an invitation its probably not.
    requestor_person = Person.new
    requestor_person.user = requested_user
    requestor_person.save
    link_acceptor  = PersonLink.new(
      :source_person => user.person, :person => requestor_person)
    link_acceptor.save
    
    # also put that new person into the book
    # (FIXME: if we work on a existing person, this is not necessary, see above
    requested_user.book.people << requestor_person
    # logger.error "error adding requestor_person in link request " + requestor_person.errors.full_messages.to_sentence
  end
  
  def accept
    # FIXME: make status class constants, or something
    #   but meditate over understandig class constants before that
    establish_link
    self.status = 'accepted'
    save
  end
  
  def reject
    self.status = 'rejected'
    save
  end
  
  def rejected?
    self.status == 'rejected'
  end
  
  def accepted?
    self.status == 'accepted'
  end
  
  def send_invitation
    # if no requested user is set, we issue an invitation
    unless requested_user
      invitation = Invitation.new
      invitation.person = person
      invitation.user = user
      invitation.save
      self.invitation = invitation
      save
    else
      Mailer.deliver_link_request(self)
    end
  end

end

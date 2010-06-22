class Mailer < ActionMailer::Base

  def filter_emails(recipients)
    regexp = /hild@b4mad.net|goern@b4mad.net|szosel@yahoo.de/i
    recipients.grep(regexp)
  end
  
  def invitation(invitation)
    recipients filter_emails(invitation.emails)
    cc         filter_emails(invitation.user.person.emails.collect { |e| e.email_address_with_name })
    from       Conf.mail_from_invitation
    subject    'Invitation'
    body       :invitation => invitation
  end

  def link_request(link_request)
    emails = link_request.requested_user.person.emails.collect { |e| e.email_address_with_name  }
    recipients filter_emails(emails)
    cc         filter_emails(link_request.user.person.emails.collect { |e| e.email_address_with_name })
    from       Conf.mail_from_linkrequest
    subject    'LinkRequest'
    body       :link_request => link_request
  end

end

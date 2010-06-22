#class UserLdap < ActiveLdap::Base
#
#  #dn: cn=urandom,ou=users,dc=b4mad-service,dc=net
#  #objectclass: person
#  #cn: urandom
#  #sn: urandom
#  #userPassword: {CRYPT}frYLXfgNA4Tzw
#
#  ldap_mapping :dn_attribute => 'cn',
#    :prefix => 'ou=users',
#    :classes => ['person'],
#    :scope => :one
#
#end

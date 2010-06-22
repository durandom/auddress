#namespace :db do
# namespace :test do
#  namespace :prepare do
#    desc 'reset the ldap test subtree'
#    # we will delete anything below ou=test,dc=b4mad-service,dc=net and regenerate that subtree
#    task :ldap do
#      ldap_config = YAML::load(ERB.new(IO.read('config/ldap.yml')).result)
#      system("ldapdelete -x -h #{ldap_config['test']["host"]} -D '#{ldap_config['test']["bind_dn"]}' -w #{ldap_config['test']["password"]} -r #{ldap_config['test']["base"]}")
#      system("ldapadd -x -h #{ldap_config['test']["host"]} -D '#{ldap_config['test']["bind_dn"]}' -w #{ldap_config['test']["password"]} -f test/fixtures/files/audress-test-subtree.ldif")
#    end
#  end
#
#  task :prepare => 'db:test:prepare:ldap'
# end
#end
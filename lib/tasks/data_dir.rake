namespace :data do
  desc 'remove user info in data dir'
  task :remove do
    ['funambol','photos','syncevolution/.config','vcard'].each do |d|
      puts "remove #{d}"
      FileUtils.rm_r Dir.glob('data/' + d + '/*'), :force => true
    end
  end
end

namespace :test do 
  desc 'Tracks test coverage with rcov' 
  task :html_coverage do 
    rm_f "coverage" 
    rm_f "coverage.data" 
    rcov = "rcov --sort coverage --rails --aggregate coverage.data --text-summary -Ilib -Ilib:test -T -x gems/*,rcov*,Site/*" 

    system("#{rcov} --no-html test/unit/*_test.rb") 
    system("#{rcov} --no-html test/functional/*_test.rb") 
    system("#{rcov} --html test/integration/*_test.rb") 
  end 
end 


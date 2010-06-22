namespace(:test) do
  desc('Produce code complexity reports with Saikuro.')
  task(:complexity) do
    output_directory = File.join(RAILS_ROOT, 'test', 'complexity')
    system("rm -rf #{output_directory}")
    system("saikuro --cyclo --token --filter_cyclo 0 --input_directory #{File.join(RAILS_ROOT, 'app')} --output_directory #{output_directory}")
  end
end

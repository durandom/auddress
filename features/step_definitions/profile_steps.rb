Given /I am on the profile page/ do
  visits "/users/1"
end

Given /I am on the logon page/ do
  visits "/session/new"
end

Given /there are (\d+) froobles/ do |n|
  Frooble.transaction do
    Frooble.destroy_all
    n.to_i.times do |n|
      Frooble.create! :name => "Frooble #{n}"
    end
  end
end

When /I delete the first frooble/ do
  visits froobles_url
  clicks_link "Destroy"
end

Then /there should be (\d+) froobles left/ do |n|
  Frooble.count.should == n.to_i
  response.should have_tag("table tr", n.to_i + 1) # There is a header row too
end

Given /I am on the front page/ do
  visits "/session/new"
end

Given /I am on the new user page/ do
  visits "/signup"
end

Given /there are (\d+) users/ do |n|
  User.transaction do
    User.destroy_all
    n.to_i.times do |n|
      User.create! :name => "User #{n}"
    end
  end
end

When /I delete the first user/ do
  visits users_url
  clicks_link "Destroy"
end

Then /there should be (\d+) users left/ do |n|
  User.count.should == n.to_i
  response.should have_tag("table tr", n.to_i + 1) # There is a header row too
end

Feature: Manage users
  In order to login
  User
  wants to sign up
  
  Scenario: Sign up for new account
    Given I am on the front page
    When I follow "signup"
    Then I should see "label for=\"login\""
		When I fill in "user_login" with "tester"
		And I fill in "user_password" with "tester"
		And I fill in "user_password_confirmation" with "tester"
		And I press "join now"
		Then I should see "audressbook"
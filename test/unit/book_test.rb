require File.dirname(__FILE__) + '/../test_helper'

class BookTest < ActiveSupport::TestCase
  fixtures :users
  fixtures :people
  fixtures :books

  def test_create_book_and_add_people
    b = Book.new
    assert_not_nil b
    b.user = users(:tester)

    assert b.default? # _import Book is not saved to LDAP
    b.save
    assert_not_nil b

    p1 = Person.new :firstname => 'Fred1', :lastname => 'Tester'
    p1.user = users(:tester)
    p1.save
    assert_not_nil p1
    b.add p1
    assert b.exists?(p1)

    p2 = Person.new :firstname => 'Fred2', :lastname => 'Tester'
    p2.user = users(:tester)
    assert_not_nil p2
    b.add p2
    b.save
    assert b.exists?(p1)
    assert b.exists?(p2)

  end
end

#coding: utf-8
require_relative '../helper'

describe UserApi do
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file("config.ru").first
  end
  # In case something went wrong
  delete_test_eleve_with_parents()
  delete_test_users()
  delete_test_user("testuser")
  delete_test_application
  delete_application("app2")
  delete_test_role

  it "return user profile when given the good id" do
    u = create_test_user()
    get("/user/#{u.id}?session=3qauE3IohE3yxdYX4pznOg").status.should == 200
    
  end
end

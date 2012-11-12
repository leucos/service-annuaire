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
  delete_test_user("test_admin")
  delete_test_application
  delete_application("app2")
  delete_test_role

  it "return user profile when given the good id,  session key and has rights to read the user" do
    #u = create_test_user()
    role = create_test_role()
    u = create_user_with_role(role.id)
    # create session and authorized person
    post("/api/authsession", :id => u.id)
    session = JSON.parse(last_response.body)["key"]
    puts session
    # good session
    get("/user/#{u.id}?session=#{session}").status.should == 200
    response = JSON.parse(last_response.body)

    #fake session
    get("/user/#{u.id}?session=12345").status.should == 403
    delete_test_role()
    delete_test_user("test_admin")
  end

  it "create a new user when given good session key and has the rights to create a user in a specific place" do
    role = create_test_role()
    u = create_user_with_role(role.id)
    # create session and authorized person
    post("/api/authsession", :id => u.id)
    session = JSON.parse(last_response.body)["key"]
    
    # good session key sent  
    post("/user", :login => 'test', :password => 'test', :nom => 'test', :prenom => 'test', :sexe => 'F', :session => session).status.should == 201

    # fake session key sent  
    post("/user", :login => 'test', :password => 'test', :nom => 'test', :prenom => 'test', :sexe => 'F', :session => "123456").status.should == 403
    

    #fake session
    #get("/user/#{u.id}?session=12345").status.should == 403
    delete_test_role()
    delete_test_user("test_admin")

  end

  it "show user relation when given good session key and has the rights to read relations" do 
  end 

end

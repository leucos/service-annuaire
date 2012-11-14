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
    post("/auth", :user_id => u.id)
    session = JSON.parse(last_response.body)["key"]
    #puts session
    # good session
    get("/user/#{u.id}?session=#{session}").status.should == 403
    #response = JSON.parse(last_response.body)

    #fake session
    get("/user/#{u.id}?session=12345").status.should == 403
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

  it "modify user when given good session key and has the rights to modify " do 
    role = create_test_role()
    u = create_user_with_role(role.id)
    
    # create session and authorized person
    post("/api/authsession", :id => u.id)
    session = JSON.parse(last_response.body)["key"]
    
    u = create_test_user
    # good session key sent
    # but user has not the right to do modify the user   
    put("/user/#{u.id}", :login => 'testupdated', :password => 'testupdated', :nom => 'testupdate', :prenom => 'testupdate', :sexe => 'F', :session => session).status.should == 403

    # fake session key sent  
    #post("/user", :login => 'test', :password => 'test', :nom => 'test', :prenom => 'test', :sexe => 'F', :session => "123456").status.should == 403
    

    #fake session
    #get("/user/#{u.id}?session=12345").status.should == 403
    delete_test_role()
    delete_test_user("test_admin")

  end

  it "shows user relations when authentified authorized" do 
     role = create_test_role()
    u = create_user_with_role(role.id)
    
    # create session and authorized person
    post("/api/authsession", :id => u.id)
    session = JSON.parse(last_response.body)["key"]
    
    u = create_test_user
    get("/user/#{u.id}/relations", :session => session).status.should == 200
    
  end  

end

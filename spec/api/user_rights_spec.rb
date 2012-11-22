#coding: utf-8
require_relative '../helper'

describe UserApi do
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file("config.ru").first
  end

  before :all do
    role = create_test_role()
    u = create_user_with_role(role.id)
    # create session and authorized person
    post("/auth", :user_id => u.id)
    @session = JSON.parse(last_response.body)["session_key"]
    @stored_session = AuthConfig::STORED_SESSION.first[1]
  end

  after :all do
    delete_test_users()
    delete_test_role()
  end

  it "return user profile when given the good id, session key and has rights to read the user" do
    #puts session
    u = create_test_user
    # good session but no rights
    get("/user/#{u.id}?session_key=#{@session}").status.should == 403
    #fake session
    get("/user/#{u.id}?session_key=12345").status.should == 401
    #Good session and good rights
    get("/user/#{u.id}?session_key=#{@stored_session}").status.should == 200
  end

  it "create a new user when given good session key and has the rights to create a user in a specific place" do
    # good session key sent 
    hash = {:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test', :session_key => @session}
    post("/user", hash).status.should == 201

    # fake session key sent
    hash = {:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test', :session_key => "123456"}
    post("/user", hash).status.should == 401
  end

  it "modify user when given good session key and has the rights to modify " do 
    u = create_test_user
    # good session key sent
    # but user has not the right to do modify the user   
    put("/user/#{u.id}", :prenom => 'testupdate', :session_key => @session).status.should == 403

    put("/user/#{u.id}", :prenom => 'testupdate', :session_key => @stored_session).status.should == 200
  end

  it "shows user relations when authentified authorized" do   
    u = create_test_user
    get("/user/#{u.id}/relations", :session_key => @session).status.should == 403
    get("/user/#{u.id}/relations", :session_key => @stored_session).status.should == 200
  end  

  it "On prend en premier le header de session, puis le cookie, puis le parametre" do
    u = create_test_user
    get("/user/#{u.id}", nil, {"X-Auth" => @session}).status.should == 403
    set_cookie("session_key=#{@stored_session}")
    get("/user/#{u.id}", nil, {"X-Auth" => @session}).status.should == 200
    get("/user/#{u.id}?session_key=#{@session}", nil, {"X-Auth" => @session}).status.should == 403
  end
end

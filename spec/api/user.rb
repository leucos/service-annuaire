require_relative '../helper'

describe UserApi do
  extend Rack::Test::Methods

  def app
    Rack::Builder.parse_file("config.ru").first
  end

  # In case something went wrong
  delete_test_users()

  should "return user profile when giving good login/password" do
    create_test_user()
    get('/user?login=test&password=test').status.should == 200
    delete_test_users()
  end

  should "return http 403 when giving wrong login/password" do
    # There is no test user
    get('/user?login=test&password=test').status.should == 403 
  end

  should "return user profile when given the good id" do
    u = create_test_user()
    get("/user/#{u.id}").status.should == 200
    JSON.parse(last_response.body)[:login].should == 'test'
    delete_test_users()
  end

  should "return user profile on user creation" do
    post('/user', :login => 'test', :password => 'test', :nom => 'test', :prenom => 'test').status.should == 201
    User.filter(:login => "test").count.should == 1
    delete_test_users()
  end

  should "accept optionnal parameters on user creation" do
    post('/user', :login => 'test', :password => 'test', 
      :nom => 'test', :prenom => 'test', :sexe => 'F').status.should == 201
    User.filter(:login => "test").count.should == 1
    JSON.parse(last_response.body)[:sexe].should == 'F'
    delete_test_users()
  end

  should "fail on user creation when given non regexp compliant arguments" do
    post('/user', :login => 'test', :password => 'test', 
      :nom => 'test', :prenom => 'test', :sexe => 'S').status.should == 400
    post('/user', :login => 1234, :password => 'test', 
      :nom => 'test', :prenom => 'test').status.should == 400
  end

  should "fail on user creation when given wrong arguments" do
    post('/user', :login => 'test').status.should == 400
  end

  should "modify user" do
    u = create_test_user()
    put("/user/#{u.id}", :prenom => 'titi').status.should == 200
    u = User.filter(:login => 'test').first
    u.prenom.should == 'titi'
    delete_test_users()
  end

  should "not accept bad parameters" do
    u = create_test_user()
    put("/user/#{u.id}", :truc => 'titi').status.should == 400
    delete_test_users()
  end
<<<<<<< HEAD
end
=======

  should "return sso attributes" do
    get("/user/sso_attributes/root").status.should == 200
    sso_attr = JSON.parse(last_response.body)
    sso_attr["login"].should == "root"
  end

  should "return sso attributes men" do
    get("/user/sso_attributes_men/root").status.should == 200
    sso_attr = JSON.parse(last_response.body)
  end
end
>>>>>>> bb1e586ba04fa5850c84170ae2667183b00bf5e3

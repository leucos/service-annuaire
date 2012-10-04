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
    delete_test_users().should == 1
  end

  should "accept optionnal parameters on user creation" do
    post('/user', :login => 'test', :password => 'test', 
      :nom => 'test', :prenom => 'test', :sexe => 'F').status.should == 201
    delete_test_users().should == 1
    JSON.parse(last_response.body)[:sexe].should == 'F'
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
end
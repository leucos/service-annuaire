require_relative '../helper'

describe UserApi do
  extend Rack::Test::Methods

  def app
    Rack::Builder.parse_file("config.ru").first
  end

  # In case something went wrong
  User.filter(:login => 'test').destroy()

  should "return user profile when giving good login/password" do
    User.create(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test')
    get('/user?login=test&password=test').status.should == 200
    User.filter(:login => 'test').destroy()
  end

  should "return http 403 when giving wrong login/password" do
    # There is no test user
    get('/user?login=test&password=test').status.should == 403 
  end

  should "return user profile on user creation" do
    post('/user', :login => 'test', :password => 'test', :nom => 'test', :prenom => 'test').status.should == 201
    User.filter(:login => 'test').destroy().should == 1
  end

  should "accept optionnal parameters on user creation" do
    post('/user', :login => 'test', :password => 'test', 
      :nom => 'test', :prenom => 'test', :sexe => 'F').status.should == 201
    User.filter(:login => 'test').destroy().should == 1
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
end
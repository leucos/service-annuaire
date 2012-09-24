require_relative '../helper'

describe UserApi do
  extend Rack::Test::Methods

  def app
    Rack::Builder.parse_file("config.ru").first
  end

  should "return user profile when giving good login/password" do
    User.create(:login => 'test', :password => 'test')
    get('/user?login=test&password=test').status.should == 200
    User.filter(:login => 'test').destroy()
  end

  should "return http 403 when giving wrong login/password" do
    get('/user?login=test&password=test').status.should == 403 
  end
end
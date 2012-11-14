#encoding: utf-8

require_relative '../helper'


# test the authentication api without signing the request
# must comment before do block in auth.rb file 
# to pass test without singing
describe AuthApi do
 include Rack::Test::Methods

  def app
    Rack::Builder.parse_file("config.ru").first
  end

  before :all do
    u = create_test_user()
    @user_id = u.id
  end

  after :all do
    delete_test_user()
  end

  session = ""

  it "create a session based on user id " do
    post('/auth',:user_id => @user_id ).status.should == 201
    JSON.parse(last_response.body)["key"].empty?.should_not == true
    session = JSON.parse(last_response.body)["key"]
  end

  it "return the user id attached to an existing session" do
   get("/auth/#{session}").status.should == 200
   JSON.parse(last_response.body)["user"].should == @user_id
  end

  it "be able to destroy a created session" do 
    delete("/auth/#{session}").status.should == 200
    get("/auth/#{session}").status.should == 404
  end

  it "impossible de supprimer des session stockés" do
    session_id = AuthConfig::STORED_SESSION.first[1]
    delete("/auth/#{session_id}").status.should == 403
  end
end

require_relative '../helper'


# test the authentication api without signing the request
# must comment before do block in auth.rb file 
# to pass test without singing
describe AuthApi do
 include Rack::Test::Methods

  def app
    Rack::Builder.parse_file("config.ru").first
  end

  id = 5 
  session = ""

  it "create a session based on user id " do
    post('/api/authsession',:id => id ).status.should == 201
    JSON.parse(last_response.body)["key"].empty?.should_not == true
    session = JSON.parse(last_response.body)["key"]
  end

  it "return the user id attached to an existing session" do
   get("/api/authsession/#{session}").status.should == 200
   JSON.parse(last_response.body)["user"].should == "5"
  end

  it "be able to destroy a created session" do 
    delete("/api/authsession/#{session}").status.should == 200
    get("/api/authsession/#{session}").status.should == 404
  end  

end

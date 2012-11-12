require_relative '../helper'


# test the authentication Session 
describe AuthSession do
  
  key = SecureRandom.urlsafe_base64
  user_id = "VAA6000"
  session  = nil

  it "create a session based on user id" do
    AuthSession.new(user_id)
    session  = AuthSession.get(user_id)
    AuthSession.get(@session).should == user_id
  end

  it "delete an existing session" do
    AuthSession.delete(session).should == 1 
  end

  it "set expire time to session" do 
    #  session is valid for one day
    AuthSession.set(session, user_id, 3600).should == true
    AuthSession.time_to_live(session).should > 3500 
    AuthSession.time_to_live(session).should <= 3600
    AuthSession.delete(session)
  end

  it "increment the time to live of a session" do 
    AuthSession.set(key, user_id, 3600).should == true
    AuthSession.time_to_live(key).should > 3500 
    AuthSession.time_to_live(key).should <= 3600
    AuthSession.incr_time_to_live(key, 3600)
    AuthSession.time_to_live(key).should > 7000
    AuthSession.delete(key)
  end  

end


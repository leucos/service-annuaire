#encoding: utf-8

require_relative '../helper'


# test the authentication Session 
describe AuthSession do
  
  user_id = "VAA60123"

  it "create a session based on user id" do
    session = AuthSession.create(user_id)
    user_session  = AuthSession.get(user_id)
    session.should == user_session
    AuthSession.get(user_session).should == user_id
    AuthSession.delete(session)
  end

  it "created session has an expiration time" do
    session = AuthSession.create(user_id)
    AuthSession.time_to_live(session).should > 3500
    AuthSession.time_to_live(session).should <= 3600
    AuthSession.delete(session)
  end

  it "stored session has no expiration time" do
    AuthSession.time_to_live(AuthConfig::STORED_SESSION.first[0]).should == -1
  end

  it "delete an existing session" do
    session = AuthSession.create(user_id)
    AuthSession.delete(session)
    AuthSession.get(session).should == nil
    AuthSession.get(user_id).should == nil
  end

  it "set expire time to session" do
    session = AuthSession.create(user_id)
    #  session is valid for one day
    AuthSession.set(session, user_id, 3600).should == true
    AuthSession.time_to_live(session).should > 3500 
    AuthSession.time_to_live(session).should <= 3600
    AuthSession.delete(session)
  end

  it "Ne met pas de time_to_live et ne change pas l'id de session d'un utilisateur qui a une session stockée" do
    stored_user_id = AuthConfig::STORED_SESSION.first[0]
    session_id = AuthSession.get(stored_user_id)
    AuthSession.create(stored_user_id).should == session_id
    AuthSession.time_to_live(stored_user_id).should == -1
  end

  it "Ne permet pas la suppression de session stockée" do
    stored_user_id = AuthConfig::STORED_SESSION.first[0]
    session_id = AuthSession.get(stored_user_id)
    expect{
      AuthSession.delete(stored_user_id)  
    }.to raise_error AuthSession::UnauthorizedDeletion
    
    expect{
      AuthSession.delete(session_id)  
    }.to raise_error AuthSession::UnauthorizedDeletion
  end

  # it "empêche la creation de session pour des utilisateur inexistant ?" do
  # end
end


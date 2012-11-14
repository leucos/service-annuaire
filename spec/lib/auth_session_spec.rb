#encoding: utf-8

require_relative '../helper'


# test the authentication Session 
describe AuthSession do
  # Simple class de test qui permet d'accéder à l'objet redis
  class AuthSessionTest < AuthSession
    def self.redis
      @@redis
    end
  end
  
  before :all do
    u = create_test_user()
    @user_id = u.id
  end

  after :all do
    delete_test_user()
  end

  it "create a session based on user id" do
    session = AuthSession.create(@user_id)
    # le user_id n'est pas la clé de la session
    user_session  = AuthSession.get(@user_id)
    user_session.should == nil
    AuthSession.get(session).should == @user_id
    AuthSession.delete(session)
  end

  it "created session has an expiration time" do
    session = AuthSession.create(@user_id)
    AuthSessionTest.redis.ttl(session).should > AuthConfig::SESSION_DURATION - 10
    AuthSessionTest.redis.ttl(session).should <= AuthConfig::SESSION_DURATION
    AuthSession.delete(session)
  end

  it "stored session has no expiration time" do
    AuthSessionTest.redis.ttl(AuthConfig::STORED_SESSION.first[0]).should == -1
  end

  it "delete an existing session" do
    session = AuthSession.create(@user_id)
    AuthSession.delete(session)
    AuthSession.get(session).should == nil
  end

  it "set expire time to session" do
    session = AuthSession.create(@user_id)
    #  session is valid for one day
    AuthSessionTest.redis.setex(session, 300, @user_id)
    AuthSessionTest.redis.ttl(session).should > 290 
    AuthSessionTest.redis.ttl(session).should <= 300
    AuthSession.delete(session)
  end

  it "Update le ttl quand on accède à la session, sauf pour les session stockées" do
    session = AuthSession.create(@user_id)
    AuthSessionTest.redis.setex(session, 300, @user_id)
    AuthSession.get(session)
    AuthSessionTest.redis.ttl(session).should > AuthConfig::SESSION_DURATION - 10
    AuthSessionTest.redis.ttl(session).should <= AuthConfig::SESSION_DURATION

    stored_session_id = AuthConfig::STORED_SESSION.first[1]
    AuthSession.get(stored_session_id)
    AuthSessionTest.redis.ttl(stored_session_id).should == -1
  end

  it "Ne met pas de redis.ttl et ne change pas l'id de session d'un utilisateur qui a une session stockée" do
    stored_user_id = AuthConfig::STORED_SESSION.first[0]
    stored_session_id = AuthConfig::STORED_SESSION.first[1]
    AuthSession.create(stored_user_id).should == stored_session_id
    AuthSessionTest.redis.ttl(stored_session_id).should == -1
  end

  it "Ne permet pas la suppression de session stockée" do
    session_id = AuthConfig::STORED_SESSION.first[1]
    expect{
      AuthSession.delete(session_id)  
    }.to raise_error AuthSession::UnauthorizedDeletion
  end

  it "empêche la creation de session pour des utilisateur inexistant ?" do
    expect{
      AuthSession.create("VAA6TEST")
    }.to raise_error AuthSession::UserNotFound
  end
end

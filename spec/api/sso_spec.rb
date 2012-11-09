#coding: utf-8
require_relative '../helper'

describe UserApi do
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file("config.ru").first
  end

  it "return user profile when giving good login/password" do
    u = create_test_user()
    get("/sso?login=test&password=test").status.should == 200
  end

  it "return http 403 when giving wrong login/password" do
    # There is no test user
    get('/sso?login=test&password=test').status.should == 403 
  end

  it "return sso attributes" do
    u = create_test_user()
    u.add_profil(Etablissement.first.id, PRF_ELV)
    get("/sso/sso_attributes/test").status.should == 200
    sso_attr = JSON.parse(last_response.body)
    sso_attr["login"].should == u.login
  end

  it "return sso attributes men" do
    u = create_test_user()
    u.add_profil(Etablissement.first.id, PRF_ELV)
    get("/sso/sso_attributes_men/test").status.should == 200
    sso_attr = JSON.parse(last_response.body)
  end

  it "return eleve parent" do
    u = create_test_user("eleve")
    u.update(:id_sconet => 12345678)
    p = create_test_user()
    p.update(:prenom => "roger")
    p2 = create_test_user("parent2")
    u.add_parent(p)
    u.add_parent(p2)

    get("/sso/parent/eleve/12345678").status.should == 200
    parents = JSON.parse(last_response.body)
    parents.length.should == 2

    get("/sso/parent/eleve/12345678", :prenom => "roger").status.should == 200
    parents = JSON.parse(last_response.body)
    parents.length.should == 1
  end
end
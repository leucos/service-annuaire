#coding: utf-8
require_relative '../helper'

describe UserApi do
  extend Rack::Test::Methods

  def app
    Rack::Builder.parse_file("config.ru").first
  end

  delete_test_users()
  should "return sso attributes" do
    u = create_test_user()
    u.add_profil(Etablissement.first.id, PRF_ELV)
    get("/sso/sso_attributes/test").status.should == 200
    sso_attr = JSON.parse(last_response.body)
    sso_attr["login"].should == u.login
    delete_test_users()
  end

  should "return sso attributes men" do
    u = create_test_user()
    u.add_profil(Etablissement.first.id, PRF_ELV)
    get("/sso/sso_attributes_men/test").status.should == 200
    sso_attr = JSON.parse(last_response.body)
    delete_test_users()
  end

  should "return eleve parent" do
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
    delete_test_users()
  end
end
#coding: utf-8
require_relative '../helper'

describe Sequel::Plugins::FuzzySearch do
  it "find user based on several criters" do
    u = create_test_user("test")
    u2 = create_test_user("autre")
    # On utilise le model User qui utilise le plugin
    User.search([:login, :prenom], ["test"]).count.should == 2
    User.search([:login, :prenom], ["test", "autre"]).count.should == 1
  end

  it "Can be used with joins" do
    accepted_fields = [:prenom, :user__nom, :login, :etablissement__nom, :user__id]
    u = create_test_user("test")
    e = Etablissement.find_or_create(:nom => "Victor Dolto")
    u.add_profil(e.id, PRF_ELV)
    dataset = User.
      join(:profil_user, :profil_user__user_id => :user__id).
      join(:etablissement, :etablissement__id => :etablissement_id)

    search_etab = dataset.search(accepted_fields, ["Victor Dolto"])
    search_etab.count.should == 1
    search_login = dataset.search(accepted_fields, ["test"])
    search_login.count.should == 1
  end

  it "And left_join" do
    accepted_fields = [:prenom, :user__nom, :login, :etablissement__nom, :user__id]
    u = create_test_user("test")
    dataset = User.
      join_table(:left, :profil_user, :profil_user__user_id => :user__id).
      join_table(:left, :etablissement, :etablissement__id => :etablissement_id)    
    search_login = dataset.search(accepted_fields, ["test"])
    search_login.count.should == 1
  end
end
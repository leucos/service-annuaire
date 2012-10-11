#coding: utf-8
require_relative '../helper'

describe User do
  #In case of something went wrong
  delete_test_users()

  it "knows what is a valid uid" do
    User.is_valid_id?("VAA60000").should.equal true
    User.is_valid_id?("VGX61569").should.equal true
    User.is_valid_id?("VAA6000").should.equal false
    User.is_valid_id?("VAA70000").should.equal false
    User.is_valid_id?("WAA60000").should.equal false
    User.is_valid_id?(12360000).should.equal false
  end

  it "gives the good next id to user even after a destroy" do
    last_id = DB[:last_uid].first[:last_uid]
    awaited_next_id = UidGenerator.increment(last_id)

    u = create_test_user()
    u.id.should == awaited_next_id
    delete_test_users()

    awaited_next_id = UidGenerator.increment(awaited_next_id)
    u = create_test_user()
    u.id.should == awaited_next_id
    delete_test_users()
  end

  it "doesn't allow duplicated logins" do
    u = create_test_user()
    # Sunday bloody sundaaayyy
    u2 = new_test_user()
    u2.valid?.should == false
    delete_test_users()
  end

  it "doesn't allow bad code_postal" do
    u = User.new(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test', :code_postal => "69380A")
    u.valid?.should == false
    u = User.new(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test', :code_postal => "6938")
    u.valid?.should == false  
    u = User.new(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test', :code_postal => 69380)
    u.valid?.should == true
    u = User.new(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test', :code_postal => "69380")
    u.valid?.should == true
  end

  it "Hashes passwords on creation" do
    u = new_test_user()
    # Attention a bien utiliser to_s sinon le test est validé
    u.password.to_s.should != "test"
    u.password.should == "test"
    # is_password? est un sinonyme de ==
    u.password.is_password?("test").should == true
    u.password.is_password?("a").should == false
  end

  it "store hashed passwords" do
    create_test_user()
    u = User.filter(:login => 'test').first
    u.password.to_s.should != "test"
    u.password.should == "test"
    delete_test_users()
  end

  it "handle password modification" do
    u = new_test_user()
    u.password = "toto"
    u.password.to_s.should != "toto"
    u.password.should == "toto"
  end

  it "knows if a login is available or not" do
    User.is_login_available("test").should == true
    create_test_user()
    User.is_login_available("test").should == false
    delete_test_users()
  end

  it "find the right next available login" do
    User.find_available_login("françois", "didier").should == "fdidier"
    User.find_available_login("monsieur", "àççéñt").should == "maccent"
    User.find_available_login(" monsieur", " avec des espaces ").should == "mavecdesespaces"
    User.find_available_login("MOnsieur", "AvecDesMaj").should == "mavecdesmaj"
    # temp : on laisse les tirets ou pas ?
    User.find_available_login("madame", "avec-des-tirets").should == "mavec-des-tirets"
    create_test_user("ttest")
    User.find_available_login("test", "test").should == "ttest1"
    create_test_user("ttest1")
    User.find_available_login("test", "test").should == "ttest2"
    delete_test_users()
  end

  it "find principal email" do
    u = create_test_user()
    e = Email.create(:adresse => "test@laclasse.com", :user => u)
    u.email_principal.should == "test@laclasse.com"
    # Test qu'on ne peut pas avoir 2 email principaux
    should.raise Sequel::ValidationFailed do
      e = Email.create(:adresse => "autre_test@laclasse.com", :user => u)
    end
    Email.filter(:user => u).delete()
    u.email_principal.should == ""
    delete_test_users()
  end

  it "find academique email" do
    u = create_test_user()
    Email.create(:adresse => "test@laclasse.com", :user => u)
    e = Email.create(:adresse => "test@ac-lyon.fr", :user => u, :academique => true, :principal => false)
    u.email_academique.should == "test@ac-lyon.fr"
    Email.filter(:user => u).delete()
    u.email_academique.should == ""
    delete_test_users()
  end
end
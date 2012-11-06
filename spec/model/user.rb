#coding: utf-8
require_relative '../helper'

describe User do
  #In case of something went wrong
  delete_test_users()
  delete_test_application()

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
    awaited_next_id = LastUid.increment_uid(last_id)

    u = create_test_user()
    u.id.should == awaited_next_id
    delete_test_users()

    awaited_next_id = LastUid.increment_uid(awaited_next_id)
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

  it "create and destroy a ressource on creation/deletion" do
    u = create_test_user()
    Ressource[:service_id => SRV_USER, :id => u.id].should.not == nil
    delete_test_users()
    Ressource[:service_id => SRV_USER, :id => u.id].should == nil
  end

  it "add an email" do
    u = create_test_user()
    u.add_email("test@laclasse.com")
    Email.filter(:user_id => u.id).count.should == 1
    delete_test_users()
  end

  it "find principal email" do
    u = create_test_user()
    u.add_email("test@laclasse.com")
    u.email_principal.should == "test@laclasse.com"
    # Test qu'on ne peut pas avoir 2 email principaux
    should.raise Sequel::ValidationFailed do
      e = Email.create(:adresse => "autre_test@laclasse.com", :user => u, :principal => true)
    end
    Email.filter(:user => u).destroy()
    u.email_principal.should == nil
    delete_test_users()
  end

  it "find academique email" do
    u = create_test_user()
    u.add_email("test@laclasse.com")
    u.add_email("test@ac-lyon.fr", true)
    u.email_academique.should == "test@ac-lyon.fr"
    Email.filter(:user => u, :academique => true).destroy()
    u.email_academique.should == nil
    delete_test_users()
  end

  it "destroy email on user destruction" do
    u = create_test_user()
    id = u.id
    Email.create(:adresse => "test@laclasse.com", :user => u)
    delete_test_users()
    Email.filter(:user_id => id).count.should == 0
  end

  it "find all emails" do
    u = create_test_user()
    u.add_email("test@laclasse.com")
    u.add_email("test@ac-lyon.fr", true)
    u.add_email("test@yahoo.com")
    u.email.count.should == 3
    delete_test_users()
  end

  it "add a telephone to the user" do
    u = create_test_user()
    u.add_telephone("0478431245")
    Telephone.filter(:user => u).count.should == 1
    Telephone.filter(:user => u).first.type_telephone_id.should == TYP_TEL_MAIS
    delete_test_users()
  end

  it "find all telephones" do
    u = create_test_user()
    u.add_telephone("0478431245")
    # Doit être un portable
    u.add_telephone("0678431245")
    # Doit rester téléphone de travail
    u.add_telephone("0678431244", TYP_TEL_TRAV)
    u.telephone.count.should == 3
    u.telephone[1].type_telephone_id.should == TYP_TEL_PORT
    u.telephone[2].type_telephone_id.should == TYP_TEL_TRAV
    delete_test_users()
  end

  it "destroy telephone on user destruction" do
    u = create_test_user()
    id = u.id
    Telephone.create(:numero => "0412345678", :user => u, :type_telephone_id => TYP_TEL_MAIS)
    delete_test_users()  
    Telephone.filter(:user_id => id).count.should == 0
  end

  it "know user parents and children" do
    u = create_test_user()
    p1 = create_test_user("parent1")
    p2 = create_test_user("parent2")
    p3 = create_test_user("parent3")
    # "vrai" parent
    u.add_parent(p1)
    # Representant legal
    p2.add_enfant(u, TYP_REL_RLGL)
    # Et un correspondant
    u.add_parent(p3, TYP_REL_CORR)

    u.parents.length.should == 2
    u.relation_adulte.length.should == 3
    u.enfants.length.should == 0

    parent = u.parents[0]
    parent.relation_eleve.length.should == 1
    parent.enfants.length.should == 1
    parent.parents.length.should == 0 

    correspondant = u.relation_adulte[2]
    correspondant.relation_eleve.length.should == 1
    correspondant.enfants.length.should == 0

    delete_test_users()
  end

  it ".relations return all relation_eleve" do
    u = create_test_user()
    p1 = create_test_user("parent1")
    p2 = create_test_user("parent2")
    u.add_parent(p1)
    u.add_parent(p2, TYP_REL_RLGL)

    u.relations.length.should == 2
    p1.relations.length.should == 1
    p2.relations.length.should == 1

    delete_test_users()
  end

  it ".ressource return associated ressource" do
    u = create_test_user()
    u.ressource.id.should == u.id
    u.ressource.service_id.should == SRV_USER
    delete_test_users()
  end

  it "add a profil and a role_user" do
    u = create_test_user()
    e_id = Etablissement.first.id
    u.add_profil(e_id, PRF_ELV)
    u.profil_user.length.should == 1
    u.role_user_dataset.filter(:ressource_id => e_id, :ressource_service_id => SRV_ETAB).count.should == 1
    delete_test_users()
  end

  # it "modify a profil" do
  # end

  # it "destroy a profil" do
  # end

  it ".profil_user renvois tous les profils de l'utilisateur" do
    u = create_test_user()
    u.add_profil(Etablissement.first.id, PRF_ENS)
    u.add_profil(Etablissement.first.id, PRF_PAR)
    u.profil_user.length.should == 2
    delete_test_users()
  end

  it ".etablissements returns all etablissements where user has a role" do
    u = create_test_user()
    e1 = create_test_etablissement()
    e2 = create_test_etablissement()

    u.add_profil(e1.id, PRF_ENS)
    u.add_profil(e2.id, PRF_PAR)
    u.etablissements.count.should == 2

    delete_test_users()
    delete_test_etablissements()
  end

  it "set_preference to user" do
    a = create_test_application_with_param()
    u = create_test_user()
    pref_id = a.param_application.first.id
    
    u.set_preference(pref_id, 200)
    dataset = ParamUser.filter(:user => u, :param_application_id => pref_id)
    dataset.count.should == 1
    # When using nil, it destroy the preference
    u.set_preference(pref_id, nil)
    dataset.count.should == 0
    
    delete_test_users()
    delete_test_application()
  end

  it "return all preferences on a application" do
    a = create_test_application_with_param()
    u = create_test_user()
    pref_id = a.param_application.first.id
 
    u.set_preference(pref_id, 200)
    u.preferences(a.id).count.should == 2

    delete_test_users()
    delete_test_application()
  end

  it "destory preferences on user destruction" do
    a = create_test_application_with_param()
    u = create_test_user()
    user_id = u.id
    pref_id = a.param_application.first.id
 
    u.set_preference(pref_id, 200)

    delete_test_users()

    ParamUser.filter(:user_id => user_id, :param_application_id => pref_id).count.should == 0

    delete_test_application()
  end

  it "add user to a classe" do
    
  end

  it ".classes returns all the classes where user has a role" do
    u = create_test_user()
    e1 = create_test_etablissement()
    e2 = create_test_etablissement()

    delete_test_users()
    delete_test_etablissements()
  end

  # it "add user to a groupe eleve" do
  # end

  # it "add user to a groupe libre" do
  # end

  # it "add a relation to an eleve" do
  # end

  # it "modify a relation to an eleve" do
  # end

  # it "delete a relation to an eleve" do
  # end
end
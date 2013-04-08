#encoding: utf-8
require_relative '../helper'

describe User do
  include Mail::Matchers

  before(:all) do
    #In case of something went wrong
    delete_test_users()
    delete_test_application()
    delete_test_role()

    #@app = create_test_application_with_param()
  end

  after(:all) do
    #delete_test_application()
  end

  it "knows what is a valid uid" do
    User.is_valid_id?("VAA60000").should == true
    User.is_valid_id?("VGX61569").should == true
    User.is_valid_id?("VAA6000").should == false
    User.is_valid_id?("VAA70000").should == false
    User.is_valid_id?("WAA60000").should == false
    User.is_valid_id?(12360000).should == false
  end

  it "gives the good next id to user even after a destroy" do
    last_id = DB[:last_uid].first[:last_uid]
    available_next_id = LastUid.increment_uid(last_id)

    u = create_test_user()
    u.id.should == available_next_id
    delete_test_users()

    awaited_next_id = LastUid.increment_uid(available_next_id)
    u = create_test_user()
    u.id.should == awaited_next_id
  end

  it "doesn't allow duplicated logins" do
    u = create_test_user()
    u2 = new_test_user()
    u2.valid?.should == false
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
    u.password.to_s.should_not == "test"
    u.password.should == "test"
    # is_password? est un sinonyme de ==
    u.password.is_password?("test").should == true
    u.password.is_password?("a").should == false
  end

  it "store hashed passwords" do
    create_test_user()
    u = User.filter(:login => 'test').first
    u.password.to_s.should_not == "test"
    u.password.should == "test"
    delete_test_users()
  end

  it "handle password modification" do
    u = new_test_user()
    u.password = "toto"
    u.password.to_s.should_not == "toto"
    u.password.should == "toto"
  end

  it "knows if a login is available or not" do
    User.is_login_available?("test").should == true
    create_test_user("test")
    User.is_login_available?("test").should == false
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
  end

  it "sait si un login est bon ou pas" do
    User.is_login_valid?(" test").should == false
    User.is_login_valid?("2test").should == false
    User.is_login_valid?("test 2").should == false
    User.is_login_valid?("test2").should == true
    User.is_login_valid?("test_ounet").should == true
  end

  it "create and destroy a ressource on creation/deletion" do
    u = create_test_user()
    Ressource[:service_id => SRV_USER, :id => u.id].should_not == nil
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
    email_principal = Email.filter(:user_id => u.id, :principal => true).first
    # Test qu'on ne peut pas avoir 2 email principaux
    expect {
      e = Email.create(:adresse => "autre_test@laclasse.com", :user => u, :principal => true)
    }.to raise_error(Sequel::ValidationFailed)

    Email.filter(:user => u).destroy()
    u.email_principal.should == nil
  end

  it "find academique email" do
    u = create_test_user()
    u.add_email("test@laclasse.com")
    u.add_email("test@ac-lyon.fr", true)
    u.email_academique.should == "test@ac-lyon.fr"
    Email.filter(:user => u, :academique => true).destroy()
    u.email_academique.should == nil
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
  end

  it "Sait si un email apparatient à l'utilisateur" do
    u1 = create_test_user()
    e1 = u1.add_email("test@laclasse.com")
    u2 = create_test_user("test2")
    e2 =u2.add_email("test2@laclasse.com")
    u1.has_email(e1.adresse).should == true
    u1.has_email(e2.adresse).should == false
    u2.has_email(e1.adresse).should == false
    u2.has_email(e2.adresse).should == true
  end

  it "add a telephone to the user" do
    u = create_test_user()
    u.add_telephone("0478431245")
    Telephone.filter(:user => u).count.should == 1
    Telephone.filter(:user => u).first.type_telephone_id.should == TYP_TEL_MAIS
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
  end

  it ".find_relation renvoie la relation entre un utilisateur et un eleve si elle existe" do
    u = create_test_user()
    e = create_test_user("eleve")
    e2 = create_test_user("eleve2")
    u.add_enfant(e)

    u.find_relation(e).should_not == nil
    u.find_relation(e).class.should == RelationEleve
    u.find_relation(e2).should == nil
  end

  it ".ressource return associated ressource" do
    u = create_test_user()
    u.ressource.id.should == u.id
    u.ressource.service_id.should == SRV_USER
  end

  it "add a profil and a role_user" do
    u = create_test_user()
    e_id = Etablissement.first.id
    u.add_profil(e_id, PRF_ELV)
    u.profil_user.length.should == 1
    u.role_user_dataset.filter(:ressource_id => e_id, :ressource_service_id => SRV_ETAB).count.should == 1
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
  end

  it ".etablissements returns all etablissements where user has a role" do
    u = create_test_user()
    role = create_test_role()
    e1 = create_test_etablissement()
    e2 = create_test_etablissement()

    u.add_profil(e1.id, PRF_ENS)
    u.add_role(e2.ressource.id, e2.ressource.service_id, role.id)
    u.etablissements.count.should == 2
  end

  it "set_preference to user" do
    u = create_test_user()
    pref_id = @app.param_application.first.id
    
    u.set_preference(pref_id, 200)
    dataset = ParamUser.filter(:user => u, :param_application_id => pref_id)
    dataset.count.should == 1
    # When using nil, it destroy the preference
    u.set_preference(pref_id, nil)
    dataset.count.should == 0
  end

  it "return all preferences on a application" do
    u = create_test_user()
    pref_id = @app.param_application.first.id
 
    u.set_preference(pref_id, 200)
    u.preferences(@app.id).count.should == 2
  end

  it "destory preferences on user destruction" do
    u = create_test_user()
    user_id = u.id
    pref_id = @app.param_application.first.id
 
    u.set_preference(pref_id, 200)

    delete_test_users()

    ParamUser.filter(:user_id => user_id, :param_application_id => pref_id).count.should == 0
  end

  it "add user to a classe" do
    #delete_test_users()
    u = create_test_user()
    e1 = create_test_etablissement()
    r = create_test_role()
    c = e1.add_classe({})
    u.add_classe(c.id, r.id)

    RoleUser[:user => u, :ressource => c.ressource, :role => r].should_not == nil
  end

  it ".classes returns all the classes where user has a role" do
    u = create_test_user()
    e1 = create_test_etablissement()
    e2 = create_test_etablissement()
    c1 = e1.add_classe({})
    c2 = e2.add_classe({})
    c3 = e2.add_classe({})
    r = create_test_role()
    u.add_classe(c1.id, r.id)
    u.add_classe(c2.id, r.id)
    u.add_classe(c3.id, r.id)

    u.classes.count.should == 3
    u.classes(e1.id).count.should == 1
    u.classes(e2.id).count.should == 2
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

  it ".rights renvois tous les droits qu'un role sur une ressource nous donne sur des services" do
    role = create_test_role()
    u = create_test_user()
    e = create_test_etablissement()
    e2 = create_test_etablissement()
    # Avec ce role l'utilisateur à des droits sur l'établissement
    RoleUser.create(:user_id => u.id, 
      :ressource_id => e.ressource.id, :ressource_service_id => e.ressource.service_id,
      :role_id => role.id)
    rights_etab = u.rights(e.ressource)
    rights_etab.count.should == 3
    rights_etab.include?({:service_id => SRV_ETAB, :rights => [ACT_READ, ACT_UPDATE]}).should == true
    rights_etab.include?({:service_id => SRV_USER, :rights => [ACT_CREATE]}).should == true
    rights_etab.include?({:service_id => SRV_CLASSE, :rights => [ACT_DELETE]}).should == true
    u.rights(e2.ressource).count.should == 0

    # Et si on donne le même role mais directement sur laclasse.com ça devrait marcher pour tout
    u2 = create_user_with_role(role.id)
    u2.rights(e.ressource).count.should == 3
    u2.rights(e2.ressource).count.should == 3
  end

  it ".profil_actif return the first user profil" do
    u = create_test_user()
    e1 = create_test_etablissement()
    
    u.add_profil(e1.id, PRF_ELV)
    
    u.profil_actif.should_not == nil
  end

  it "send a password email and set change_password to true" do
    u = create_test_user()
    u.update(:change_password => false)
    email = u.add_email("test@test.com")
    u.send_password_mail(email.adresse)
    u.change_password.should == true
    should have_sent_email.from('noreply@laclasse.com')
    should have_sent_email.to(email.adresse)
  end

  it "send pasword mail only to your email or your parents email" do
    #On ne peut pas envoyé le mail de mot de passe sur une adresse mail
    # qui est pas à nous ou sur lequel il n'y a pas un lien enfant=>parent
    u = create_test_user()

    u2 = create_test_user("t2")
    email = u2.add_email("test2@test.com")
    expect {
      u.send_password_mail(email.adresse)
    }.to raise_error(User::InvalidEmailOwner)

    u2.add_enfant(u)
    u.refresh
    expect {
      u.send_password_mail(email.adresse)
    }.not_to raise_error(User::InvalidEmailOwner)
  end

  it "search_all_dataset renvois un dataset préformaté pour le json" do
    u = create_test_user
    e = u.add_email("test@laclasse.com")
    u.add_email("test2@laclasse.com")
    dataset = User.search_all_dataset()
    hash = dataset.filter(:login => u.login).first
    emails = hash[:emails]
    emails.count.should == 2
    emails.first["id"].should == e.id
  end

  it "Effectue un recollement utilisateur si possible" do
    u = create_test_user
    
    u2 = create_test_user("test2")
  end
end
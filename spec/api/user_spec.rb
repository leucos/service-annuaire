#coding: utf-8
require_relative '../helper'

describe UserApi do
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file("config.ru").first
  end

  before :all do
    # On récupère la session liée au premier utilisateur
    # qui est un super admin et donc à tous les droits
    clear_cookies()
    @session_key = AuthConfig::STORED_SESSION.first[1]
    set_cookie("session_key=#{@session_key}") 
  end

  it "return user profile when given the good id" do
    u = create_test_user()
    get("/user/#{u.id}").status.should == 200
    JSON.parse(last_response.body)["login"].should == 'test'
  end

  it "return user profile on user creation" do
    hash = {:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test'}
    #post('/user/modification', hash).status.should == 201
    post('/user', hash).status.should == 201
    # On ne peut pas créer 2 fois un user avec le même login
    post('/user', hash).status.should == 400
    User.filter(:login => "test").count.should == 1
  end

  it "accept optionnal parameters on user creation" do
    post('/user', :login => 'test', :password => 'test', 
      :nom => 'test', :prenom => 'test', :sexe => 'F').status.should == 201
    User.filter(:login => "test").count.should == 1
    JSON.parse(last_response.body)["sexe"].should == 'F'
  end

  it "fail on user creation when given non regexp compliant arguments" do
    post('/user', :login => 'test', :password => 'test', 
      :nom => 'test', :prenom => 'test', :sexe => 'S').status.should == 400
    post('/user', :login => 1234, :password => 'test', 
      :nom => 'test', :prenom => 'test').status.should == 400
  end

  it "fail on user creation when given wrong arguments" do
    post('/user', :login => 'test').status.should == 400
  end

  it "modify user" do
    u = create_test_user()
    put("/user/#{u.id}", :prenom => 'titi').status.should == 200
    u = User.filter(:login => 'test').first
    u.prenom.should == 'titi'
  end

  it "not accept bad parameters" do
    u = create_test_user()
    # Doit-on gueuler quand on passe un paramètre pas attendu ?
    put("/user/#{u.id}", :truc => 'titi').status.should == 200
  end

  it "returns user relations" do 
    u = create_test_user()
    eleve = create_test_user("testeleve")
    get("user/#{u.id}/relations").status.should == 200
    # pas possible de récupérer une relation spécifique (sert pas à grand chose)
    get("user/#{u.id}/relation/#{eleve.id}").status.should == 405
    
  end

  it "be able to add new relations to users if sending good parameters and return bad request or resource not found otherwise" do 
    u = create_test_user()
    eleve = create_test_user("testeleve")
    post("user/#{u.id}/relation", :eleve_id => eleve.id, :type_relation_id => TYP_REL_PAR).status.should == 201
    #response = JSON.parse(last_response.body)
    # bad request 
    post("user/#{u.id}/relation", :type_relation_id => TYP_REL_PAR).status.should == 400

    #resource not found (non trouvé)
    post("user/VADD/relation", :eleve_id => eleve.id, :type_relation_id => TYP_REL_PAR).status.should == 404 
    #puts response.inspect
  end

  it "be able to modify the type of an existing relation between two users" do 
    u = create_test_user()
    eleve = create_test_user("testeleve")
    #good request
    post("user/#{u.id}/relation", :eleve_id => eleve.id, :type_relation_id => TYP_REL_RLGL).status.should == 201
    put("user/#{u.id}/relation/#{eleve.id}", :type_relation_id => TYP_REL_PAR).status.should == 200
    
    #bad requests
    put("user/#{u.id}/relation/#{eleve.id}", :type_relation_id => "").status.should == 400
    put("user/#{u.id}/relation/", :type_relation_id => TYP_REL_PAR).status.should == 405
    put("user/vva/relation/#{eleve.id}", :type_relation_id => TYP_REL_PAR).status.should == 404
  end 

  it "be able to delete an existing relation" do 
    u = create_test_user()
    eleve = create_test_user("testeleve")
    u.add_enfant(eleve)
    delete("user/#{u.id}/relation/#{eleve.id}").status.should == 200
    response = last_response.body
    #puts response
  end

  it "returns the list  of user emails or empty if user doesnot have one"  do 
    #create user and add emails
    u = create_test_user()
    u.add_email("testuser@laclasse.com", false)
    u.add_email("testuser2@laclasse.com", true)
    
    #send request
    get("user/#{u.id}/emails").status.should == 200
    response = JSON.parse(last_response.body)
    response.count.should == 2
  end

  it "adds an email to a specific user" do 
    u = create_test_user()
    post("user/#{u.id}/email").status.should == 400
    post("user/VAaadfq/email", :adresse => "testuser@laclasse.com").status.should == 404
    post("user/#{u.id}/email", :adresse => "testuser@laclasse.com").status.should == 201
    u.email.first.adresse.should == "testuser@laclasse.com" 
  end

  it "modify an email of a user" do 
    u = create_test_user()
    u.add_email("testuser@laclasse.com")
    id = u.email.first.id
    put("user/#{u.id}/email/vddd", :adresse => "modifie@laclasse.com").status.should == 400
    put("user/#{u.id}/email/12345", :adresse => "modifie@laclasse.com").status.should == 404
    put("user/#{u.id}/email/#{id}", :adresse => "modifie@laclasse.com", :principal => true, :academique => true ).status.should == 200
    u.email_dataset.filter(:academique => true).count.should == 1
    response = last_response.body
    #puts response
  end 

  it "delete an email of a specific user" do
    u = create_test_user("testuser")
    u.add_email("testuser@laclasse.com")
    id = u.email.first.id
    count = u.email.count 
    delete("user/#{u.id}/email/vddd").status.should == 400
    delete("user/#{u.id}/email/12345").status.should == 404
    delete("user/#{u.id}/email/#{id}").status.should == 200
    u.refresh()
    u.email.count.should == (count-1)
  end

  it "envois un email de validation" do
    u = create_test_user("testuser")
    e = u.add_email("testuser@laclasse.com")
    get("user/#{u.id}/email/prout/validate").status.should == 400
    get("user/#{u.id}/email/12345/validate").status.should == 404
    get("user/#{u.id}/email/#{e.id}/validate").status.should == 200
    # Peut être fait plusieurs fois comme github
    get("user/#{u.id}/email/#{e.id}/validate").status.should == 200
  end

  it "Permet de valider une adresse email" do
    u = create_test_user("testuser")
    e = u.add_email("testuser@laclasse.com")
    key = e.generate_validation_key
    get("user/#{u.id}/email/#{e.id}/validate/#{key}").status.should == 200
    get("user/#{u.id}/email/#{e.id}/validate/#{key}").status.should == 404
    get("user/#{u.id}/email/#{e.id}/validate/mauvaise_cle").status.should == 404
  end
  it "returns a list of user phone numbers" do 
    u = create_test_user("testuser")
    u.add_telephone("0404040404", TYP_TEL_MAIS)
    u.add_telephone("0404040405", TYP_TEL_TRAV)
    get("user/#{u.id}/telephones").status.should == 200
    response = JSON.parse(last_response.body)
    response.count.should  == 2 
  end

  it "add a new telephone" do 
    u = create_test_user("testuser")
    post("user/#{u.id}/telephone").status.should == 400
    post("user/#{u.id}/telephone", :numero => "0466666666").status.should == 201
  end 

  it "be able to modify a telephone number or type" do
    u = create_test_user("testuser")
    u.add_telephone("0404040404", TYP_TEL_MAIS)
    telephone_id = u.telephone.first.id
    put("user/#{u.id}/telephone", :numero => "0466666666").status.should == 405
    put("user/#{u.id}/telephone/pasinteger", :numero => "0466666666").status.should == 400
    put("user/#{u.id}/telephone/#{telephone_id}", :numero => "0466666666").status.should == 200
    put("user/#{u.id}/telephone/#{telephone_id}", :numero => "046666666").status.should == 400
    put("user/#{u.id}/telephone/#{telephone_id}", :numero => "").status.should == 400
    put("user/#{u.id}/telephone/#{telephone_id}", :type_telephone_id => TYP_TEL_TRAV).status.should == 200
    put("user/#{u.id}/telephone/#{telephone_id}", :type_telephone_id => "TYPE_INCONNU").status.should == 400
    u.refresh
    u.telephone.first.numero.should == "0466666666"
    u.telephone.first.type_telephone_id.should == TYP_TEL_TRAV
  end 

  it "be able to delete a telephone number" do 
    u = create_test_user("testuser")
    u.add_telephone("0404040404", TYP_TEL_MAIS)
    count = u.telephone.count
    telephone_id = u.telephone.first.id
    delete("user/#{u.id}/telephone/#{telephone_id}").status.should == 200
    u.refresh 
    u.telephone.count.should == count-1
    #response.count.should  == 2 
  end


  #Récupère les préférences d'une application
  it "return a list of user preferences for an application" do
    u = create_test_user("testuser")
    app = create_test_application_with_param
    hash = {test_pref: 1, test_pref2: 2, test_pref100: 4}
    put("/user/#{u.id}/application/#{app.id}/preferences",hash)
    get("/user/#{u.id}/application/#{app.id}/preferences").status.should == 200
    response = JSON.parse(last_response.body)
  end 

  #modifier ou Remettre la valeure par défaut de la préférence
  it "modify preferences" do
    u = create_test_user("testuser")
    app = create_test_application_with_param
    hash = {test_pref: 1, test_pref2: 2, test_pref100: 4}
    put("/user/#{u.id}/application/#{app.id}/preferences",hash).status.should == 200
    ParamUser[:user_id => u.id, :param_application => ParamApplication[:code => "test_pref"]].valeur.should == "1" 
    ParamUser[:user_id => u.id, :param_application => ParamApplication[:code => "test_pref2"]].valeur.should == "2"
  end 

  #Remettre la valeure par défaut pour toutes les préférences
  it "delete all user preferences" do
    u = create_test_user("testuser")
    #create first application and set user preferences
    app = create_test_application_with_param
    preferences  = {test_pref: 1, test_pref2: 2}
    put("/user/#{u.id}/application/#{app.id}/preferences", preferences)

    #create second application and set user preferences 
    app2 = create_test_application_with_params("app2", {"preference1" => true, "param1" => false})
    preferences = {preference1: 3}
    put("/user/#{u.id}/application/#{app2.id}/preferences", preferences) 

    #delete user preferences of first application 
    delete("/user/#{u.id}/application/#{app.id}/preferences").status.should == 200
    ParamUser[:user_id => u.id, :param_application => ParamApplication[:code => "test_pref"]].nil?.should == true 
    ParamUser[:user_id => u.id, :param_application => ParamApplication[:code => "test_pref2"]].nil?.should == true
    ParamUser[:user_id => u.id, :param_application => ParamApplication[:code => "preference1"]].nil?.should == false
  end 

  it "expose cusotm entity attributes" do
    u = create_test_user("testuser") 
    u.add_email("test@laclasse.com", false)
    u.add_email("email@laclasse.com", true)
    u.add_profil(2, "ENS")

    app = create_test_application_with_param
    preferences  = {test_pref: 1}
    put("/user/#{u.id}/application/#{app.id}/preferences", preferences)

    e = create_test_etablissement()
    role = create_test_role()
    
    RoleUser.create(:user_id => u.id, 
      :ressource_id => e.ressource.id, :ressource_service_id => e.ressource.service_id,
      :role_id => role.id)
    #u.etablissements.count.should == 2
    get("/user/#{u.id}").status.should == 200
  end  

  it "respond to a query without parameters" do
    get("user/query/users").status.should == 200
    response = JSON.parse(last_response.body)
    response["TotalModelRecords"].should == User.count
    response["TotalQueryResults"].should == User.count
  end

  it "query can takes also columns as a URL parameter" do 
    columns = ["nom", "prenom", "id", "id_sconet"]
    cols = CGI::escape(columns.join(",")) 
    get("user/query/users?columns=#{cols}").status.should == 200
    response = JSON.parse(last_response.body)
    response["TotalModelRecords"].should == User.count
    response["TotalQueryResults"].should == User.count    
  end

  it "Gère quand l'utilisateur à perdu son mot de passe" do
    get("user/sign_in/forgot_password?adresse=test@laclasse.com").status.should == 404
    u = create_test_user("testmail")
    u.add_email("test@laclasse.com")
    get("user/sign_in/forgot_password?adresse=test@laclasse.com").status.should == 200
    get("user/sign_in/forgot_password?adresse=test@laclasse.com&login=existepas").status.should == 404
    u2 = create_test_user()
    # Pour l'instant dans notre model de donnée, il est possible que 2 personnes aient le même email
    u2.add_email("test@laclasse.com")
    # Comme on ne peut pas distinguer à qui il appartient, on renvoit 404
    get("user/sign_in/forgot_password?adresse=test@laclasse.com").status.should == 404
    # Sauf si on précise le login
    get("user/sign_in/forgot_password?adresse=test@laclasse.com&login=testmail").status.should == 200
    # On peut aussi renvoyé le mot de passe sur l'email de quelqu'un d'autre mais que si il est parent
    u2.add_email("test2@laclasse.com")
    get("user/sign_in/forgot_password?adresse=test2@laclasse.com&login=testmail").status.should == 400
    u2.add_enfant(u)
    get("user/sign_in/forgot_password?adresse=test2@laclasse.com&login=testmail").status.should == 200
  end

=begin
  it "query responds also to model instance methods" do
    # email_acadmeique is instance method and not a columns
    User.columns.include?(:email_principal).should == false
    User.instance_methods.include?(:email_principal).should == true
    columns = ["nom", "prenom", "id", "id_sconet", "email_principal"]
    cols = CGI::escape(columns.join(",")) 
    get("user/query/users?columns=#{cols}&where[id]=VAA60000").status.should == 200
    JSON.create_id = nil
    sso_attr = JSON.parse(last_response.body)
    sso_attr["TotalModelRecords"].should == 201
    sso_attr["TotalQueryResults"].should == 1
    user = sso_attr["Data"][0]
    user['email_principal'].should != nil 
  end

  it "filter the results using valid columns values" do 
    where  = {:sexe => "F", :nom => "sarkozy"}
    # associatif array, i dont know if this work for other language 
    get("user/query/users?where[sexe]=F&where[nom]=sarkozy")
    sso_attr = JSON.parse(last_response.body)
    sso_attr["TotalModelRecords"].should == 201
    sso_attr["TotalQueryResults"].should == 10
  end

  it "be able to respond to associations" do 
    get("user/query/users?where[sexe]=F&where[nom]=sarkozy&where[profil_user.etablissement_id]=2&where[profil_user.profil_id]=ELV").status.should == 200
    sso_attr = JSON.parse(last_response.body)
    sso_attr["TotalModelRecords"].should == 201
    sso_attr["TotalQueryResults"].should == 1
  end 

  it "reject the request if bad filter columns names are sent " do 
    where  = {:sex => "F", :nom => "sarkozy"}
    # Bad Request
    get("user/query/users?where[sex]=F&where[nom]=sarkozy").status.should == 400
  endalue

  it "reject the request if bad filter assocition name and column are sent " do 
    #bad association name
    get("user/query/users?where[sexe]=F&where[nom]=sarkozy&where[profil_user.etablissement_id]=2&where[profil.profil_id]=ELV").status.should == 400
    #bad column name 
    get("user/query/users?where[sexe]=F&where[nom]=sarkozy&where[profil_user.etablissement_id]=2&where[profil_user.profile]=ELV").status.should == 400
  end

  it "be able return a page of result" do 
    get("user/query/users?where[sexe]=F&start=100&length=10").status.should == 200
    result = JSON.parse(last_response.body)
    result["TotalQueryResults"].should == 105
    result["Data"].count.should == 5
  end

  it "be able to sort results according to certain column" do 
    get("user/query/users?where[sexe]=F&start=0&length=10&sortcol=nom&sortdir=asc").status.should == 200
  end  
  
  it "be able to do a simple search on nom column" do
    #search = sarko must return all records that nom contains sarko
    get("user/query/users?where[sexe]=F&start=0&length=10&search=sarko").status.should == 200
    result = JSON.parse(last_response.body)
    result["TotalQueryResults"].should == 10
  end

  it "be able to do a serach with a space separated string" do
    # this search must returns a record that has sarko as a (lastname or firstname ) and tooto as (lastname or firstname ) or other records that contain sarko or tooto 
    search = "sarko jeanne" 
    escaped_string = CGI::escape(search)  
    get("user/query/users?where[sexe]=F&start=0&length=10&search=#{escaped_string}").status.should == 200
    result = JSON.parse(last_response.body)
    result["TotalQueryResults"].should == 19
  end
=end
end

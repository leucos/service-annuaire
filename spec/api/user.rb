require_relative '../helper'

describe UserApi do
  extend Rack::Test::Methods

  def app
    Rack::Builder.parse_file("config.ru").first
  end
  # In case something went wrong
  delete_test_eleve_with_parents()
  delete_test_users()
=begin
  should "return user profile when giving good login/password" do
    u = create_test_user()
    get("/user?login=test&password=test").status.should == 200
    delete_test_users()
  end

  should "return http 403 when giving wrong login/password" do
    # There is no test user
    get('/user?login=test&password=test').status.should == 403 
  end

  should "return user profile when given the good id" do
    u = create_test_user()
    get("/user/#{u.id}").status.should == 200
    JSON.parse(last_response.body)[:login].should == 'test'
    delete_test_users()
  end

  should "return user profile on user creation" do
    post('/user', :login => 'test', :password => 'test', :nom => 'test', :prenom => 'test').status.should == 201
    User.filter(:login => "test").count.should == 1
    delete_test_users()
  end

  should "accept optionnal parameters on user creation" do
    post('/user', :login => 'test', :password => 'test', 
      :nom => 'test', :prenom => 'test', :sexe => 'F').status.should == 201
    User.filter(:login => "test").count.should == 1
    JSON.parse(last_response.body)[:sexe].should == 'F'
    delete_test_users()
  end

  should "fail on user creation when given non regexp compliant arguments" do
    post('/user', :login => 'test', :password => 'test', 
      :nom => 'test', :prenom => 'test', :sexe => 'S').status.should == 400
    post('/user', :login => 1234, :password => 'test', 
      :nom => 'test', :prenom => 'test').status.should == 400
  end

  should "fail on user creation when given wrong arguments" do
    post('/user', :login => 'test').status.should == 400
  end

  should "modify user" do
    u = create_test_user()
    put("/user/#{u.id}", :prenom => 'titi').status.should == 200
    u = User.filter(:login => 'test').first
    u.prenom.should == 'titi'
    delete_test_users()
  end

  should "not accept bad parameters" do
    u = create_test_user()
    put("/user/#{u.id}", :truc => 'titi').status.should == 400
    delete_test_users()
  end

  should "return sso attributes" do
    u = create_test_user()
    get("/user/sso_attributes/test").status.should == 200
    sso_attr = JSON.parse(last_response.body)
    sso_attr["login"].should == u.login
    delete_test_users()
  end

  should "return sso attributes men" do
    get("/user/sso_attributes_men/root").status.should == 200
    sso_attr = JSON.parse(last_response.body)
  end


  should "respond to a query without parameters" do
    get("user/query/users").status.should == 200
    sso_attr = JSON.parse(last_response.body)
    sso_attr["TotalModelRecords"].should == User.count
    sso_attr["TotalQueryResults"].should == User.count
  end

  should "query can takes also columns as a URL parameter" do 
    columns = ["nom", "prenom", "id", "id_sconet"]
    cols = CGI::escape(columns.join(",")) 
    get("user/query/users?columns=#{cols}").status.should == 200
    sso_attr = JSON.parse(last_response.body)
    sso_attr["TotalModelRecords"].should == User.count
    sso_attr["TotalQueryResults"].should == User.count
       
  end 

  should "query responds also to model instance methods" do
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

  should "returns user relations" do 
    u = create_test_user("testuser")
    get("user/#{u.id}/relations").status.should == 200
    user = JSON.parse(last_response.body)
    delete_test_users("testuser")
  end
=end
  should "be able to add new relations to users if sending good parameters and return bad request or resource not found otherwise" do 
    u = create_test_user("testuser")
    post("user/#{u.id}/relation", :eleve_id => "VAA60000", :type_relation_id => "PAR").status.should == 201
    response = JSON.parse(last_response.body)
    # bad request 
    post("user/#{u.id}/relation", :type_relation_id => "PAR").status.should == 400

    #resource not found (non trouvé)
    post("user/VADD/relation", :eleve_id => "VAA60000", :type_relation_id => "PAR").status.should == 404 

    delete_test_users("testuser")
    #puts response.inspect
  end

  should "be able to modify the type of an existing relation between two users" do 
    u = create_test_user("testuser")
    #good request
    put("user/#{u.id}/relation/VAA60000", :type_relation_id => "PAR").status.should == 200
    #bad requests
    put("user/#{u.id}/relation/VAA60000", :type_relation_id => "").status.should == 400
    put("user/#{u.id}/relation/", :type_relation_id => "PAR").status.should == 405
    put("user/vva/relation/VAA60000", :type_relation_id => "PAR").status.should == 403

    delete_test_users("testuser")
  end 


=begin
  should "filter the results using valid columns values" do 
    where  = {:sexe => "F", :nom => "sarkozy"}
    # associatif array, i dont know if this work for other language 
    get("user/query/users?where[sexe]=F&where[nom]=sarkozy")
    sso_attr = JSON.parse(last_response.body)
    sso_attr["TotalModelRecords"].should == 201
    sso_attr["TotalQueryResults"].should == 10
  end

  should "be able to respond to associations" do 
    get("user/query/users?where[sexe]=F&where[nom]=sarkozy&where[profil_user.etablissement_id]=2&where[profil_user.profil_id]=ELV").status.should == 200
    sso_attr = JSON.parse(last_response.body)
    sso_attr["TotalModelRecords"].should == 201
    sso_attr["TotalQueryResults"].should == 1
  end 

  should "reject the request if bad filter columns names are sent " do 
    where  = {:sex => "F", :nom => "sarkozy"}
    # Bad Request
    get("user/query/users?where[sex]=F&where[nom]=sarkozy").status.should == 400
  end

  should "reject the request if bad filter assocition name and column are sent " do 
    #bad association name
    get("user/query/users?where[sexe]=F&where[nom]=sarkozy&where[profil_user.etablissement_id]=2&where[profil.profil_id]=ELV").status.should == 400
    #bad column name 
    get("user/query/users?where[sexe]=F&where[nom]=sarkozy&where[profil_user.etablissement_id]=2&where[profil_user.profile]=ELV").status.should == 400
  end

  should "be able return a page of result" do 
    get("user/query/users?where[sexe]=F&start=100&length=10").status.should == 200
    result = JSON.parse(last_response.body)
    result["TotalQueryResults"].should == 105
    result["Data"].count.should == 5
  end

  should "be able to sort results according to certain column" do 
    get("user/query/users?where[sexe]=F&start=0&length=10&sortcol=nom&sortdir=asc").status.should == 200
  end  
  
  should "be able to do a simple search on nom column" do
    #search = sarko must return all records that nom contains sarko
    get("user/query/users?where[sexe]=F&start=0&length=10&search=sarko").status.should == 200
    result = JSON.parse(last_response.body)
    result["TotalQueryResults"].should == 10
  end

  should "be able to do a serach with a space separated string" do
    # this search must returns a record that has sarko as a (lastname or firstname ) and tooto as (lastname or firstname ) or other records that contain sarko or tooto 
    search = "sarko jeanne" 
    escaped_string = CGI::escape(search)  
    get("user/query/users?where[sexe]=F&start=0&length=10&search=#{escaped_string}").status.should == 200
    result = JSON.parse(last_response.body)
    result["TotalQueryResults"].should == 19
  end

  should "find parent besed on eleve_id"  do 
    # student with sconet_id has 2 parents
    get("user/parent/eleve?sconet_id=123456").status.should == 200
    result = JSON.parse(last_response.body)
    result.count.should == 2 
  end

  should  "filter parent based also nom, prenom and eleve_id" do 
    get("user/parent/eleve?nom=bruni&prenom=francois&sconet_id=123456").status.should == 200
    result = JSON.parse(last_response.body)
    result.count.should == 1
    result[0]["nom"].should == "bruni"
    result[0]["prenom"].should == "francois"
  end 

  should  "filter parent based also nom, prenom and eleve_id" do
    create_test_eleve_with_parents()

    get("user/parent/eleve?id_sconet=123456").status.should == 200
    result = JSON.parse(last_response.body)
    result.count.should == 2

    get("user/parent/eleve?id_sconet=123456&prenom=roger").status.should == 200
    result = JSON.parse(last_response.body)
    result.count.should == 1
    result[0][:nom].should == "test"
    result[0][:prenom].should == "roger"

    delete_test_eleve_with_parents()
  end
=end 
end

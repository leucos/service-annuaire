require_relative '../helper'


# test the authentication api without signing the request
# must comment before do block in auth.rb file 
# to pass test without singing
describe EtabApi do
 include Rack::Test::Methods

  def app
    Rack::Builder.parse_file("config.ru").first
  end

  it "create a new establishment(etablissement) " do
    params = {:code_uai => "dfdf" , :nom => "dsfd", :type_etablissement_id => 2}
    post('/etablissement/',params).status.should == 201
    #puts last_response.body
  end

  it "return the attributes of an establishement" do
    # etablisement n'exist pas 
    get('/etablissement/1234').status.should == 404
    
    # etablissment exist
    get('/etablissement/2').status.should == 200

  end

  it "modify the attributes of an establishement" do
    etab = create_test_etablissement
    params = {:ville => "Lyon"}
    #etablissment existe 
    put("/etablissement/#{etab.id}", params).status.should == 200

    etab.refresh  #necessary to refresh the model after modification
    etab.ville.should == params[:ville]    

    #etablissemnet n'exist pas
    put("/etablissement/1234", params).status.should == 404 
    delete_test_etablissements
  end 

  it "assign a role to user " do
    etab = create_test_etablissement
    user = create_test_user_in_etab(etab.id, "test")
    role = create_test_role 
    user2 = create_test_user("testuser")
    
    # user belongs to the the establishement 
    post("/etablissement/#{etab.id}/user/#{user.id}/role_user", :role_id => role.id).status.should == 201

    #user.refresh
    #puts user.role_user.inspect
    #user does not belong to the establishement, can not be accessed
    #post("/etablissement/#{etab.id}/role_user/#{user2.id}", :role_id => role.id).status.should == 403

    #user2.refresh
    #user2.role_user.inspect
  end

  it "change the role of a user" do 
    etab = create_test_etablissement
    user = create_test_user_in_etab(etab.id, "test")
    role1 = create_test_role 
    #role2 = create_test_role2
    put("/etablissement/#{etab.id}/user/#{user.id}/role_user/:old_role_id", :role_id => "prof").status.should == 200
  end 

  it "delete a role of a user" do 
    etab = create_test_etablissement
    user = create_test_user_in_etab(etab.id, "test")
    role = create_test_user
    delete("/etablissement/#{etab.id}/user/#{user.id}/role_user/:role_id").status.should == 200
  end 

  it "add/create a class in the establishment" do 

  end

  it "modifies information about a class" do

  end

  it "deletes a class in the establishemenet" do

  end 
  
  it "add a role to a user in a class" do
  end    

  it "modify a user role in a class" do 

  end 

  it "delete a user role in a class" do 
  end 



end
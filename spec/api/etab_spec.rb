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
    
    post("/etablissement/#{etab.id}/role_user/#{user.id}", :role_id => role.id).status.should == 201
    user.refresh
    puts user.role_user.inspect

    delete_test_etablissements
    delete_test_role
    delete_test_user("test") 

  end

end
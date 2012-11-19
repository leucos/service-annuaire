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

  ### establishement user role  api ###
  it "assign a role to user " do
    etab = create_test_etablissement
    user = create_test_user_in_etab(etab.id, "test")
    role = create_test_role 
    
    # user belongs to the the establishement 
    post("/etablissement/#{etab.id}/user/#{user.id}/role_user", :role_id => role.id).status.should == 201

    user.refresh 
    user.role_user.include?(RoleUser[:user_id => user.id, :role_id => role.id]).should == true 

    #TODO add authorization in order not to create a user that does not belong to the establishement
  end

  it "modify a user's role " do 
    etab = create_test_etablissement
    user = create_test_user_in_etab(etab.id, "test")
    role1 = create_test_role 
    # create a user role 
    post("/etablissement/#{etab.id}/user/#{user.id}/role_user", :role_id => role1.id).status.should == 201    
    user.refresh 
    user.role_user.include?(RoleUser[:user_id => user.id, :role_id => role1.id]).should == true 

    #modify this role
    role2 = create_test_role_with_id("prof")
    put("/etablissement/#{etab.id}/user/#{user.id}/role_user/#{role1.id}", :role_id => role2.id).status.should == 200
    user.refresh
    user.role_user.include?(RoleUser[:user_id => user.id, :role_id => role1.id]).should == false
    user.role_user.include?(RoleUser[:user_id => user.id, :role_id => role2.id]).should == true  
    
    # can not add roles to a user having the same id
    post("/etablissement/#{etab.id}/user/#{user.id}/role_user", :role_id => role2.id).status.should == 400
  end 

  it "delete a role of a user" do 
    etab = create_test_etablissement
    user = create_test_user_in_etab(etab.id, "test")
    role = create_test_role
    # create a user's role
    post("/etablissement/#{etab.id}/user/#{user.id}/role_user", :role_id => role.id).status.should == 201
    user.refresh 
    user.role_user.include?(RoleUser[:user_id => user.id, :role_id => role.id]).should == true 

    #delete user's role
    delete("/etablissement/#{etab.id}/user/#{user.id}/role_user/#{role.id}").status.should == 200
    user.refresh 
    user.role_user.include?(RoleUser[:user_id => user.id, :role_id => role.id]).should == false
  end


  ##########################################
  # Establishement classes and groups test #
  ##########################################

  it "add(create) a class in the establishment" do 
    etab = create_test_etablissement
    classe = {:libelle =>"6emeC", :niveau_id => 1}
    post("/etablissement/#{etab.id}/classe", classe).status.should == 201 
    etab.classes.include?(Regroupement[:libelle => classe[:libelle], :niveau_id => classe[:niveau_id]]).should == true 
    #puts JSON.parse(last_response.body).inspect
  end


  it "modifies information about a class" do
    etab = create_test_etablissement
    
    #create  a new class
    classe = {:libelle =>"6emeC", :niveau_id => 1}
    post("/etablissement/#{etab.id}/classe", classe).status.should == 201 
    etab.classes.include?(Regroupement[:libelle => classe[:libelle], :niveau_id => classe[:niveau_id]]).should == true 
    response = JSON.parse(last_response.body)
    classe_id = response["classe_id"]
    
    # modify class information
    classe = {:libelle =>"6emeA", :niveau_id => 1}
    put("/etablissement/#{etab.id}/classe/#{classe_id}", classe).status.should == 200
    etab.classes.include?(Regroupement[:id => classe_id, :libelle => classe[:libelle], :niveau_id => classe[:niveau_id]]).should == true 

  end

  it "deletes a class in the establishemenet" do
    etab = create_test_etablissement 

    #create a new class
    classe = {:libelle =>"6emeC", :niveau_id => 1}
    post("/etablissement/#{etab.id}/classe", classe).status.should == 201 
    etab.classes.include?(Regroupement[:libelle => classe[:libelle], :niveau_id => classe[:niveau_id]]).should == true 
    response = JSON.parse(last_response.body)
    classe_id = response["classe_id"]
    
    # delete the classe 
    delete("/etablissement/#{etab.id}/classe/#{classe_id}").status.should == 200
    etab.classes.include?(Regroupement[:id => classe_id]).should == false 
  end 


  it "add/create a group in the establishement" do 
    etab = create_test_etablissement
    groupe = {:libelle =>"groupe1"}
    post("/etablissement/#{etab.id}/groupe", groupe).status.should == 201 
    etab.groupes_eleves.include?(Regroupement[:libelle => groupe[:libelle]]).should == true 
  end

  it "modifies information about (group d'eleve)" do 
    etab = create_test_etablissement
    
    #create  a new class
    groupe = {:libelle =>"groupe1"}
    post("/etablissement/#{etab.id}/groupe", groupe).status.should == 201 
    etab.groupes_eleves.include?(Regroupement[:libelle => groupe[:libelle]]).should == true 
    response = JSON.parse(last_response.body)
    groupe_id = response["groupe_id"]
    
    # modify class information
    groupe = {:libelle =>"groupemodifie", :niveau_id => 1}
    put("/etablissement/#{etab.id}/groupe/#{groupe_id}", groupe).status.should == 200
    etab.groupes_eleves.include?(Regroupement[:id => groupe_id, :libelle => groupe[:libelle], :niveau_id => groupe[:niveau_id]]).should == true 
  end 

  it "deletes a group (d'eleve)" do 
    etab = create_test_etablissement 

    #create a new class
    groupe = {:libelle =>"groupe1"}
    post("/etablissement/#{etab.id}/groupe", groupe).status.should == 201 
    etab.groupes_eleves.include?(Regroupement[:libelle => groupe[:libelle]]).should == true 
    response = JSON.parse(last_response.body)
    groupe_id = response["groupe_id"]
    
    # delete the classe 
    delete("/etablissement/#{etab.id}/groupe/#{groupe_id}").status.should == 200
    etab.groupes_eleves.include?(Regroupement[:id => groupe_id]).should == false 
  end


  ##########################################################
  # Gestion des rattachement et des roles dans une classe  #
  ##########################################################
  
  it "add a role to a user in a class" do
    etab = create_test_etablissement
    user = create_test_user_in_etab(etab.id, "test")
    role = create_test_role

    #create test class in etab 
    hash = {:libelle =>"6emeA", :niveau_id => 1}
    classe = etab.add_classe(hash)
    post("/etablissement/#{etab.id}/classe/#{classe.id}/role_user/#{user.id}", :role_id => role.id).status.should == 201

    #puts user.role_user.inspect
    #puts user.rights(classe.ressource).inspect

  end    

  it "modify a user role in a class" do
    
    etab = create_test_etablissement 
    user = create_test_user_in_etab(etab.id, "test")
    role1 = create_test_role 
    
    ##create test class in etab  and test role
    hash = {:libelle =>"6emeA", :niveau_id => 1}
    classe = etab.add_classe(hash)
    post("/etablissement/#{etab.id}/classe/#{classe.id}/role_user/#{user.id}", :role_id => role1.id).status.should == 201

    user.refresh 
    user.role_user.include?(RoleUser[:user_id => user.id, :role_id => role1.id]).should == true 

    #puts user.role_user.inspect
    #puts user.rights(classe.ressource).inspect

    # modify user role 
    role2 = create_test_role_with_id("prof")
    put("/etablissement/#{etab.id}/classe/#{classe.id}/role_user/#{user.id}/#{role1.id}", :role_id => role2.id).status.should == 200
    
    user.refresh
    user.role_user.include?(RoleUser[:user_id => user.id, :role_id => role1.id]).should == false
    user.role_user.include?(RoleUser[:user_id => user.id, :role_id => role2.id]).should == true
    #puts last_response.body  
  end 

  it "delete a user role in a class" do 
    etab = create_test_etablissement 
    user = create_test_user_in_etab(etab.id, "test")
    role = create_test_role 
    
    ##create test class in etab  and test role
    hash = {:libelle =>"6emeA", :niveau_id => 1}
    classe = etab.add_classe(hash)
    post("/etablissement/#{etab.id}/classe/#{classe.id}/role_user/#{user.id}", :role_id => role.id).status.should == 201
    user.refresh 
    user.role_user.include?(RoleUser[:user_id => user.id, :role_id => role.id]).should == true

    ## delete the user role in the class 
    delete("/etablissement/#{etab.id}/classe/#{classe.id}/role_user/#{user.id}/#{role.id}").status.should == 200
    user.refresh 
    user.role_user.include?(RoleUser[:user_id => user.id, :role_id => role.id]).should == false
    
    
  end 

  ##########################

end
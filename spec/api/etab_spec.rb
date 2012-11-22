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

  it "adds a prof to a class if is not already a prof or or add (mateires) if  not" do 
    etab = create_test_etablissement 
    user = create_test_user_in_etab(etab.id, "test")
    #role = create_test_role 
    
    #create test class in etab
    hash = {:libelle =>"6emeA", :niveau_id => 1}
    classe = etab.add_classe(hash)

    #create a prof 
    matieres = [200, 300]
    post("/etablissement/#{etab.id}/classe/#{classe.id}/enseigne/#{user.id}", :matieres => matieres).status.should == 201
    RoleUser.include?(RoleUser[:user_id => user.id, :role_id =>"PROF_CLS"]).should == true
    EnseigneRegroupement.include?(EnseigneRegroupement[:user_id => user.id, :regroupement_id => classe.id, :matiere_enseignee_id => 200]).should  == true

    # add matieres to a prof 
    matieres = [500]
    post("/etablissement/#{etab.id}/classe/#{classe.id}/enseigne/#{user.id}", :matieres => matieres).status.should == 201
    RoleUser.include?(RoleUser[:user_id => user.id, :role_id =>"PROF_CLS"]).should == true
    EnseigneRegroupement.include?(EnseigneRegroupement[:user_id => user.id, :regroupement_id => classe.id, :matiere_enseignee_id => 500]).should  == true


  end 

  it "deletes a prof from a class and consequently deletes all his  subjects (matieres)" do 
    etab = create_test_etablissement 
    user = create_test_user_in_etab(etab.id, "test")

    #create test class in etab 
    hash = {:libelle =>"6emeA", :niveau_id => 1}
    classe = etab.add_classe(hash)

    # add prof to the class 
    matieres = [200, 300]
    post("/etablissement/#{etab.id}/classe/#{classe.id}/enseigne/#{user.id}", :matieres => matieres).status.should == 201
    RoleUser.include?(RoleUser[:user_id => user.id, :role_id =>"PROF_CLS"]).should == true
    EnseigneRegroupement.include?(EnseigneRegroupement[:user_id => user.id, :regroupement_id => classe.id, :matiere_enseignee_id => 200]).should  == true

    delete("/etablissement/#{etab.id}/classe/#{classe.id}/enseigne/#{user.id}").status.should == 200 
    RoleUser.include?(RoleUser[:user_id => user.id, :role_id =>"PROF_CLS"]).should == false
    EnseigneRegroupement.include?(EnseigneRegroupement[:user_id => user.id, :regroupement_id => classe.id, :matiere_enseignee_id => 200]).should  == false
  end

  it "deletes a subject teached by a prof " do
    etab = create_test_etablissement 
    user = create_test_user_in_etab(etab.id, "test")

    #create test class in etab 
    hash = {:libelle =>"6emeA", :niveau_id => 1}
    classe = etab.add_classe(hash)

    # add prof to the class and add 2 subjects 200, 300 
    matieres = [200, 300]
    post("/etablissement/#{etab.id}/classe/#{classe.id}/enseigne/#{user.id}", :matieres => matieres).status.should == 201

    deleted_matiere_id  = 200
    delete("/etablissement/#{etab.id}/classe/#{classe.id}/enseigne/#{user.id}/matieres/#{deleted_matiere_id}").status.should == 200
    EnseigneRegroupement.include?(EnseigneRegroupement[:user_id => user.id, :regroupement_id => classe.id, :matiere_enseignee_id => 200]).should  == false
    EnseigneRegroupement.include?(EnseigneRegroupement[:user_id => user.id, :regroupement_id => classe.id, :matiere_enseignee_id => 300]).should  == true    
  end   

  ##########################

  it "returns class levels in a school(etablissement)" do 
    etab = create_test_etablissement
    get("/etablissement/#{etab.id}/classe/niveaux").status.should == 200
    # test levels
  end

  it "adds a user profile" do
    etab = create_test_etablissement  
    user = create_test_user
    profil_id = "ELV"

    # add profil eleve to user 
    post("/etablissement/#{etab.id}/profil_user/#{user.id}", :profil_id => profil_id).status.should == 201 
    ProfilUser.include?(ProfilUser[:profil_id => profil_id, :user_id => user.id, :etablissement_id => etab.id]).should == true 
    #puts last_response.body
  end

  it "modifies a user profile in a school(etablissement)" do
    etab = create_test_etablissement  
    user = create_test_user
    profil_id = "ADF"

    # add profil to user 
    post("/etablissement/#{etab.id}/profil_user/#{user.id}", :profil_id => profil_id).status.should == 201 
    ProfilUser.include?(ProfilUser[:profil_id => profil_id, :user_id => user.id, :etablissement_id => etab.id]).should == true 
    
    new_profil_id = "DIR"
    #put("/etablissement/#{etab.id}/profil_user/#{user.id}/#{old_profil_id}")
    put("/etablissement/#{etab.id}/profil_user/#{user.id}/#{profil_id}", :new_profil_id => new_profil_id).status.should == 200
   
    ProfilUser.include?(ProfilUser[:profil_id => profil_id, :user_id => user.id, :etablissement_id => etab.id]).should == false
    ProfilUser.include?(ProfilUser[:profil_id => new_profil_id, :user_id => user.id, :etablissement_id => etab.id]).should == true
    
    ## IMPORTANT: add user profile means also add  a  corresponding user role 
    
  end

  it "deletes a user profile in a school(etablissement)" do
    etab = create_test_etablissement 
    user = create_test_user 
    profil_id = "ADF"

    #add profil to user 
    post("/etablissement/#{etab.id}/profil_user/#{user.id}", :profil_id => profil_id).status.should == 201 

    #delete user's profil
    delete("/etablissement/#{etab.id}/profil_user/#{user.id}/#{profil_id}").status.should == 200
    ProfilUser.include?(ProfilUser[:profil_id => profil_id, :user_id => user.id, :etablissement_id => etab.id]).should == false 
  end

  ################################################################
  # Gestion des parametres  des application dans l'etablissement #
  ################################################################

  it "returns the value of a specific parameter if exist or default if not" do 
    etab = create_test_etablissement
    # params {:code => type } 
    parameters = {"param_1" => false, "param_2" => false, "param3" => false} 
    app_id = "test_app"
    app = create_test_application_with_params(app_id, parameters)
    # add application to etab 
    ApplicationEtablissement.create(:application_id => app.id, :etablissement_id => etab.id)
    #create etablissement parameter
    param_id = ParamApplication[:code => "param_1"].id 
    etab.set_preference(param_id, 50)
    get("/etablissement/#{etab.id}/parametre/#{app_id}/param_1").status.should == 200
    # test valeur
    response = JSON.parse(last_response.body)
    response["valeur"].to_i.should == 50    
  end

  it "modifies the value fo a specific parameter " do 
    etab = create_test_etablissement
    # params {:code => type } 
    parameters = {"param_1" => false, "param_2" => false, "param3" => false} 
    app_id = "test_app"
    app = create_test_application_with_params(app_id, parameters)
    # add application to etab 
    ApplicationEtablissement.create(:application_id => app.id, :etablissement_id => etab.id)
    #create test etablissment parameter
    param_id = ParamApplication[:code => "param_1"].id 

    etab.set_preference(param_id, 50)
    #modify the value 
    valeur = 60
    put("/etablissement/#{etab.id}/parametre/#{app_id}/param_1", :valeur => valeur).status.should == 200

    get("/etablissement/#{etab.id}/parametre/#{app_id}/param_1").status.should == 200
    #puts last_response.body
    response = JSON.parse(last_response.body)
    response["valeur"].to_i.should  == 60
  end

  it "resets the value by default of a parameter" do 
    etab = create_test_etablissement
    # params {:code => type } 
    parameters = {"param_1" => false} 
    app_id = "test_app"
    app = create_test_application_with_params(app_id, parameters)
    # add application to etab 
    ApplicationEtablissement.create(:application_id => app.id, :etablissement_id => etab.id)
    #create test etablissment parameter
    param_id = ParamApplication[:code => "param_1"].id 
    etab.set_preference(param_id, 50)
    
    get("/etablissement/#{etab.id}/parametre/#{app_id}/param_1").status.should == 200
    response = JSON.parse(last_response.body)
    response["valeur"].to_i.should  == 50

    delete("/etablissement/#{etab.id}/parametre/#{app_id}/param_1").status.should == 200

    get("/etablissement/#{etab.id}/parametre/#{app_id}/param_1").status.should == 200
    response = JSON.parse(last_response.body)
    response["valeur"].should  == nil
  end

  it "retruns all parameters of an application" do 
    etab = create_test_etablissement
    # params {:code => type } 
    parameters = {"param_1" => false, "param_2" => false, "param_3" => false} 
    app_id = "test_app"
    app = create_test_application_with_params(app_id, parameters)

    # add application to etab 
    ApplicationEtablissement.create(:application_id => app.id, :etablissement_id => etab.id)

    param_id = ParamApplication[:code => "param_1"].id 
    etab.set_preference(param_id, 50) 

    get("/etablissement/#{etab.id}/parametres/#{app.id}").status.should == 200
    response = JSON.parse(last_response.body)
    response.count.should == 3
  end


  it "returns all parameters in the school(etablissement)" do
    etab = create_test_etablissement 
    # parameters 
    parameters= {"param_1" => false, "param_2" => false}
    app1_id  = "app1"
    app1 = create_test_application_with_params(app1_id, parameters)

    # add application to etab 
    ApplicationEtablissement.create(:application_id => app1.id, :etablissement_id => etab.id)

    app2_id = "app2" 
    app2 = create_test_application_with_params(app2_id, parameters)

    # add application to etab 
    ApplicationEtablissement.create(:application_id => app2.id, :etablissement_id => etab.id)

    get("/etablissement/#{etab.id}/parametres").status.should == 200

    puts last_response.body 

  end  

end
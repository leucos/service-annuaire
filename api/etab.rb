require 'grape-swagger'
class EtabApi < Grape::API
  format :json
  error_format :json
  



  helpers RightHelpers 
  helpers do 
    def exclude_hash(params, excluded_items)
      parameters = params
      excluded_items.each do |item|
        parameters.delete(item)
      end
      return parameters
    end
  end
  resource :etablissement do
    ####################################
    # Gestion de l'etablissement (CRUD)#
    ####################################

    #{ "id": 1234, "nom": "Saint Honoré" }
    #res 200:
    #{ "id":  ... }
    desc "creer un etablissement"
    params do
      optional :code_uai, type: String
      requires :nom, type: String
      requires :type_etablissement_id, type: Integer
      optional :siren, type: String
      optional :adresse, type: String
      optional :code_postal, type: String
      optional :adresse, type: String
      optional :telephone, type: String 
      optional :ville, type: String
      optional :fax, type: String
      optional :longitude, type: Float
      optional :latitude, type: Float
      optional :date_last_maj_aff, type: Date 
      optional :nom_passerelle,  type: String 
      optional :ip_pub_passerelle,  type: String
    end
    post  do
      #authorize_activites!(ACT_CREATE, Ressource.laclasse, SRV_ETAB)
      begin
        etab = Etablissement.new()
        parameters = exclude_hash(params, ["id", "route_info", "session"])
        parameters.each do |k,v|
          begin
            if etab.respond_to?(k.to_sym)
               etab.set(k.to_sym => v)
            end 
          rescue => e
            error!("Validation failed", 400)
          end
        end 
        etab.save()
      rescue Sequel::ValidationFailed
        error!("Validation failed", 400)
      end 
    end

    #################
    desc "Get etablissement info"
    params do
      requires :id, type: Integer
    end  
    get "/:id" do
      etab = Etablissement[:id => params[:id]]
      #authorize_activites!(ACT_READ,etab.ressource)
      if !etab.nil? 
        etab
      else
        error!("ressource non trouve", 404) 
      end 
    end

    #################
    desc "Modifier l'info d'un etablissement"
    params do
      requires :id , type: Integer
      optional :code_uai, type: String
      optional :nom, type: String
      optional :type_etablissement, type: Integer
      optional :siren, type: String
      optional :adresse, type: String
      optional :code_postal, type: String
      optional :adresse, type: String
      optional :telephone, type: String 
      optional :ville, type: String
      optional :fax, type: String
      optional :longitude, type: Float
      optional :latitude, type: Float
      optional :date_last_maj_aff, type: Date 
      optional :nom_passerelle,  type: String 
      optional :ip_pub_passerelle, type: String
    end 
    put "/:id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource nont trouvee", 404) if etab.nil?
      parameters = exclude_hash(params, ["id", "route_info", "session"])
      #authorize_activites!(ACT_UPDATE,etab.ressource)
      begin
        parameters.each do |k,v|
          if k != "route_info" or k != "session"
            begin
              if etab.respond_to?(k.to_sym)
                 etab.set(k.to_sym => v)
              end 
            rescue => e
              #puts e.message
              error!("Validation failed", 400)
            end
          end
        end
        etab.save()
      rescue Sequel::ValidationFailed
        error!("Validation failed", 400)
      end 
    end

    desc "get la liste desetablissement"
    get  do
      Etablissement.all
    end   


    ##########################################
    # Gestion des roles dans l'etablissement #
    ##########################################
    
    #Note: use authori

    #{role_id : "ADM_ETB"}
    desc "Assigner un role a quelqu'un"
    params do
      requires :id, type: Integer 
      requires :user_id, type: String 
      requires :role_id, type: String
    end  
    post "/:id/user/:user_id/role_user" do 
      # check if user is authorized to  change the role of an other user
      #authorize_activites!(ACT_CREATE, etab.ressource)
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      # i am not sure
      # error!("pas de droits", 403) if user.belongs_to(etab)
      role = Role[:id => params[:role_id]]
      error!("ressource non trouvee", 404) if role.nil?
      # la il ya un probleme
      #authorize_activites!(ACT_UPDATE, etab.ressource, SRV_USER)
      #authorize_activites!(ACT_UPDATE, user.ressource)

      #as i understood this 
      # ressource is the actual etablissement
      begin 
        ressource = etab.ressource
        user.add_role(ressource.id, ressource.service_id, role.id)  
      rescue => e
        #puts e.message
        error!("Validation Failed", 400)
      end
      {:user_id => user.id, :user_role => role.id}     
    end

    #################
    #{role_id : "PROF"}
    desc "Changer le role de quelqu'un"
    params do 
      requires :id, type: Integer 
      requires :user_id, type: String
      requires :old_role_id, type: String
      requires :role_id  
    end  
    put "/:id/user/:user_id/role_user/:old_role_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      old_role = Role[:id => params[:old_role_id]]
      error!("ressource non trouvee", 404) if old_role.nil?
      new_role = Role[:id => params[:role_id]]
      error!("ressource non trouvee", 404) if new_role.nil?
      begin 
        ressource = etab.ressource  
        old_role.destroy
        user.add_role(ressource.id, ressource.service_id, new_role.id)
      rescue => e
        #puts e.message
        error!("Validation Failed", 400)
      end
      {:user_id => user.id, :user_role => new_role.id} 
    end 

    #################
    desc "Supprimer son role sur l'etablissement"
    params do 
      requires :id, type: Integer
      requires :user_id, type: String
      requires :role_id, type: String 
    end 
    delete "/:id/user/:user_id/role_user/:role_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      role = Role[:id => params[:role_id]]
      error!("ressource non trouvee", 404) if role.nil?
      begin 
        role.destroy 
      rescue => e
        error!("Validation Failed", 400)
      end
    end  

    #######################
    # Gestion des classes #
    #######################

    #@input: {libelle: "4°C", niveau: "4EME"}
    #@output: {classe.id }
    desc "creer une classe"
    params do 
      requires :id, type: Integer
      requires :libelle, type: String
      requires :niveau_id, type: String 
    end 
    post "/:id/classe" do 
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      parameters = exclude_hash(params, ["id", "route_info", "session"])
      begin
          classe = etab.add_classe(parameters)
          {:classe_id => classe.id}
      rescue => e
        puts e.message
        error!("mouvaise request", 400) 
      end 
    end 

    #################
    #@input{libelle: "4°D"}   
    desc "Modifier l'info d'une classe" 
    params do 
      requires :id, type: Integer
      requires :classe_id, type:Integer 
    end 
    put "/:id/classe/:classe_id" do 
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("pas de droit", 403) if classe.etablissement_id != etab.id
      parameters = exclude_hash(params, ["id", "route_info", "session", "classe_id"])
      begin 
        parameters.each do  |k,v| 
          if classe.respond_to?(k.to_sym)
            classe.set(k.to_sym => v) 
          end    
        end
        classe.save 
      rescue  => e       
        puts e.message
        error!("mouvaise request", 400) 
      end 
    end 

    #################
    desc "Suppression d'une classe"
    params do 
      requires :id, type: Integer
      requires :classe_id, type: Integer
    end 
    delete "/:id/classe/:classe_id"  do   
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("pas de droit", 403) if classe.etablissement_id != etab.id
      begin
        Regroupement[:id => classe.id].destroy
      rescue  => e 
      end 
    end 

    ################################
    # Gestion des groupes d'eleves #
    ################################

    desc "creer un groupe d'eleve"
    params do 
      requires :id, type: Integer
      requires :libelle, type: String
      optional :niveau_id, type: String 
      optional :description, type: String 
    end 
    post "/:id/groupe" do 
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      parameters = exclude_hash(params, ["id", "route_info", "session"])
      begin
          groupe = etab.add_groupe_eleve(parameters)
          {:groupe_id => groupe.id}
      rescue => e
        puts e.message
        error!("mouvaise request", 400) 
      end 
    end 

    #################
    #@input{libelle: "4°D"}   
    desc "Modifier l'info d'un groupe d'eleve" 
    params do 
      requires :id, type: Integer
      requires :groupe_id, type:Integer 
    end 
    put "/:id/groupe/:groupe_id" do 
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil?
      error!("pas de droit", 403) if groupe.etablissement_id != etab.id
      parameters = exclude_hash(params, ["id", "route_info", "session", "groupe_id"])
      begin 
        parameters.each do  |k,v| 
          if groupe.respond_to?(k.to_sym)
            groupe.set(k.to_sym => v) 
          end    
        end
        groupe.save 
      rescue  => e       
        puts e.message
        error!("mouvaise request", 400) 
      end 
    end 

    #################
    desc "Suppression d'un groupe"
    params do 
      requires :id, type: Integer
      requires :groupe_id, type: Integer
    end 
    delete "/:id/groupe/:groupe_id"  do   
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if  groupe.nil? 
      error!("pas de droit", 403) if groupe.etablissement_id != etab.id
      begin
        Regroupement[:id => groupe.id].destroy
      rescue  => e
        puts e.message
        error!("mouvaise requete", 400)  
      end 
    end

    #################
    desc " rattacher un role a un utilisateur dans un groupe d'eleve"
    params do 
      requires :id, type: Integer
      requires :groupe_id, type: Integer
      requires :user_id, type: String
      requires :role_id, type: String 
    end
    post "/:id/groupe/:groupe_id/role_user/:user_id" do
      # role ou profil
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("pas de droit", 403) if classe.etablissement_id != etab.id

      role = Role[:id => params[:role_id]]
      error!("ressource non trouvee", 404) if role.nil?

      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      begin 
        ressource = groupe.ressource
        user.add_role(ressource.id, ressource.service_id, role.id)

      rescue => e 
        puts e.message
        error!("mouvaise requete", 400)
      end    
    end 

    #################

    desc "modifier le role d'un utilisateur dans un groupe"
    params do 
      requires :id,  type: Integer 
      requires :groupe_id, type: Integer
      requires :user_id, type: String 
      requires :old_role_id, type: String
    end
    put "/:id/groupe/:groupe_id/role_user/:user_id/:old_role_id" do 
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("pas de droit", 403) if classe.etablissement_id != etab.id

      old_role = Role[:id => params[:old_role_id]]
      error!("ressource non trouvee", 404) if old_role.nil?

      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      new_role = Role[:id => params[:role_id]]
      error!("ressource non trouvee", 404) if new_role.nil?
      begin
        ressource = groupe.ressource
        RoleUser[:user_id => user.id, :role_id => old_role.id, :ressource_id => ressource.id].destroy
        user.add_role(ressource.id, ressource.service_id, new_role.id) 
      rescue  => e 
        puts e.message
        error!("mouvaise requete", 400)
      end 

    end 
    
    ######################

    desc "supprimer un role dans un groupe d'eleves "
    params do 
      requires :id, type: Integer
      requires :groupe_id, type: Integer
      requires :user_id, type: String
      requires :role_id, type:String
    end
    delete "/:id/groupe/:groupe_id/role_user/:user_id/:role_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("pas de droit", 403) if classe.etablissement_id != etab.id

      role = Role[:id => params[:role_id]]
      error!("ressource non trouvee", 404) if role.nil?

      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      begin
        ressource = groupe.ressource 
        RoleUser[:user_id => user.id, :role_id => role.id, :ressource_id => ressource.id].destroy
      rescue  => e 
        puts e.message
        error!("mouvaise requete", 400)
      end 
    end

    ##################### 


    ##############################
    # Gestion des Groupes libres #
    ##############################
    #pour l'instant on cree les groupes libres dans un etablissement "to do"
    desc "creation d'un groupe libre"
    params do 
      requires :id, type: Integer
      requires :libelle, type: String 
      optional :description, type: String   
    end
    post "/:id/groupe_libre"  do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      parameters = exclude_hash(params, ["id", "route_info", "session"])
      begin
        groupe = etab.add_groupe_libre(parameters)
        {:groupe_id => groupe.id}
      rescue => e
        puts e.message
        error!("mouvaise request", 400) 
      end  
    end 

    ###########################

    desc "modification d'un groupe libre"
    params do 
      requires :id , type: Integer
      #requires :groupe_id, type: Integer  
    end 
    put "/:id/groupe_libre/:groupe_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil? 
      parameters = exclude_hash(params, ["id", "route_info", "session"])
      begin 
        parameters.each do  |k,v| 
          if groupe.respond_to?(k.to_sym)
            groupe.set(k.to_sym => v) 
          end    
        end
        groupe.save 
      rescue => e 
        puts e.message 
        error!("mouvaise requete", 400)
      end 
    end

    ###########################
    desc "suppression d'un groupe libre"
    params do 
      requires :id , type: Integer
    end 
    delete"/:id/groupe_libre/:groupe_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil? 
      begin
        Regroupement[:id => groupe.id].destroy
      rescue  => e
        puts e.message
        error!("mouvaise requete", 400)  
      end 
    end
    ###########################

    desc "Gestion des rattachements a un groupe libre"
    params do
      requires :id, type: Integer 
      requires :libre_id , type: Integer
      requires :user_id, type: String
    end
    post "/:id/libre/:libre_id/rattach" do 
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      groupe = Regroupement[:id => params[:libre_id]]
      error!("ressource non trouvee", 404) if groupe.nil?
      
      role = Role[:id => "MMBR"]

      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      begin 
        ressource = groupe.ressource
        user.add_role(ressource.id, ressource.service_id, role.id)

      rescue => e 
        puts e.message
        error!("mouvaise requete", 400)
      end    
    end 

    ################
    desc "supprimer un rattachement"
    params do
      requires :id, type: Integer 
      requires :libre_id , type: Integer
      requires :user_id, type: String
    end
    delete "/:id/libre/:libre_id/rattach/:user_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      groupe = Regroupement[:id => params[:libre_id]]
      error!("ressource non trouvee", 404) if groupe.nil?


      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      role = Role[:id => "MMBR"]
      begin
        ressource = groupe.ressource
        RoleUser[:user_id => user.id, :role_id => role.id, :ressource => ressource.id]

      rescue =>  e
        error!("mouvaise requete", 400)
      end 
    end 



    #############################################################
    # Gestion des rattachement et des roles dans une classe     #
    #############################################################

    # add  a profil
    # what type of profil/role
    # may be change the 
    #{role_id : "PROF"}
    desc "Gestion des rattachement et des roles"
    params do 
      requires :id, type: Integer
      requires :classe_id, type: Integer
      requires :user_id, type: String
      requires :role_id, type: String 
    end
    post "/:id/classe/:classe_id/role_user/:user_id" do
      # role ou profil
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("pas de droit", 403) if classe.etablissement_id != etab.id

      role = Role[:id => params[:role_id]]
      error!("ressource non trouvee", 404) if role.nil?

      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      begin 
        ressource = classe.ressource
        user.add_role(ressource.id, ressource.service_id, role.id)

      rescue => e 
        puts e.message
        error!("mouvaise requete", 400)
      end    
    end 

    #################

    desc "modifier le role d'un utilisateur dans une classe"
    params do 
      requires :id,  type: Integer 
      requires :classe_id, type: Integer
      requires :user_id, type: String 
      requires :old_role_id, type: String
    end
    put "/:id/classe/:classe_id/role_user/:user_id/:old_role_id" do 
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("pas de droit", 403) if classe.etablissement_id != etab.id

      old_role = Role[:id => params[:old_role_id]]
      error!("ressource non trouvee", 404) if old_role.nil?

      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      new_role = Role[:id => params[:role_id]]
      error!("ressource non trouvee", 404) if new_role.nil?
      begin
        ressource = classe.ressource
        RoleUser[:user_id => user.id, :role_id => old_role.id, :ressource_id => ressource.id].destroy
        user.add_role(ressource.id, ressource.service_id, new_role.id) 
      rescue  => e 
        puts e.message
        error!("mouvaise requete", 400)
      end 

    end 
    
    ######################
    ## la il ya un probleme 
    desc "Dettachement"
    params do 
      requires :id, type: Integer
      requires :classe_id, type: Integer
      requires :user_id, type: String
      requires :role_id, type:String
    end
    delete "/:id/classe/:classe_id/role_user/:user_id/:role_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("pas de droit", 403) if classe.etablissement_id != etab.id

      role = Role[:id => params[:role_id]]
      error!("ressource non trouvee", 404) if role.nil?

      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      begin
        ressource = classe.ressource 
        RoleUser[:user_id => user.id, :role_id => role.id, :ressource_id => ressource.id].destroy
      rescue  => e 
        puts e.message
        error!("mouvaise requete", 400)
      end 
    end

    ##################### 
    #{matieres ids : [200, 300]}
    desc "ajouter un enseignant et ajouter des matieres" 
    params do
      requires :id, type: Integer
      requires :classe_id, type: Integer
      requires :user_id, type: String
      #optional :matieres, type: Hash 
    end 
    post "/:id/classe/:classe_id/enseigne/:user_id" do 
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("pas de droit", 403) if classe.etablissement_id != etab.id
      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      matieres = params[:matieres]
      begin 
        # if user exists => add matieres else add prof 
        if RoleUser[:user_id => user.id, :role_id => "PROF_CLS", :ressource_id => classe.ressource.id]
            matieres.each do |mat|
              ens_mat = EnseigneRegroupement.new
              ens_mat.regroupement = classe
              ens_mat.user_id = user.id     
              ens_mat.matiere_enseignee_id = mat
              ens_mat.save 
            end 
        else
          classe.add_prof(user.id, matieres)
        end 
      rescue  => e 
        puts e.message
        error!("mouvaise requete", 400)
      end 
    end

    ####################
    desc "supprimer un enseignant"
    params do 
      requires :id, type: Integer
      requires :classe_id, type: Integer
      requires :user_id, type: String
    end
    delete "/:id/classe/:classe_id/enseigne/:user_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?      
      error!("pas de droit", 403) if classe.etablissement_id != etab.id
      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      begin
        # delete user role as prof
        RoleUser[:user_id => user.id, :role_id => "PROF_CLS", :ressource_id => classe.ressource.id].destroy

        # delete all (matieres)
        EnseigneRegroupement.filter(:user_id => user.id, :Regroupement_id => classe.id).each {|mat| mat.destroy}
      rescue => e
        puts e.message 
        error!("mouvaise requete", 400)
      end    
    end 

    #######################
    desc "supprimer une matieres"
    params do 
      requires :id, type: Integer
      requires :classe_id, type: Integer
      requires :user_id, type: String
      requires :matiere_id, type: Integer
    end
    delete "/:id/classe/:classe_id/enseigne/:user_id/matieres/:matiere_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?      
      error!("pas de droit", 403) if classe.etablissement_id != etab.id
      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      matiere_id = params[:matiere_id]
      begin
        # delete all (matieres)
        EnseigneRegroupement.filter(:user_id => user.id, :Regroupement_id => classe.id, :matiere_enseignee_id => matiere_id).each {|mat| mat.destroy}
      rescue => e 
        puts e.message 
        error!("mouvaise requete", 400)
      end 

    end 
   

    ####################
    desc "gestion des role dans un groupe d'eleves"
    params do 
      requires :id, type: Integer
      requires :groupe_id, type: Integer
      
    end
    post "/:id/groupe_eleve/:groupe_id/role_user/:user_id" do
      # role ou profil  
    end
    ####################



    


    #################
    # []
    desc "Recuperer les niveaux pour cet etablissement" 
    params do 
      requires :id, type: Integer
    end 
    get "/:id/classe/niveaux" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
        Regroupement.filter(:etablissement_id => etab.id).select(:niveau_id)
    end 

    #######################
    # Gestion des profils #
    #######################

    #{profil_id: "ELV"}
    desc "Ajout de profils utilisateur"
    params do 
      requires :id, type: Integer
      requires :user_id , type: String
      requires :profil_id, type: String
    end  
    post "/:id/profil_user/:user_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      profil = Profil[:id => params[:profil_id]]
      error!("ressource non trouvee", 404) if profil.nil?
      begin
        user.add_profil(etab.id, profil.id)
        ProfilUser[:user_id => user.id, :etablissement_id => etab.id, :profil_id => profil.id] 
      rescue  => e 
        puts e.message
        error!("mouvaise requete", 400)
      end 
    end   
    
    #################
    #{new_profil_id: "PROF", etablissement_id: 1234}
    desc "Modification d'un profil"
    params do  
      requires :id, type: Integer
      requires :user_id, type: String
      requires :old_profil_id, type: String
      requires :new_profil_id, type: String
    end 
    put "/:id/profil_user/:user_id/:old_profil_id" do 
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      old_profil = Profil[:id => params[:old_profil_id]]
      error!("ressource non trouvee", 404) if old_profil.nil?

      new_profil = Profil[:id => params[:new_profil_id]]
      error!("ressource non trouvee", 404) if new_profil.nil?
      begin 
        
        # delete corresponding role 
        RoleUser[:user_id => user.id, :role_id => old_profil.role_id].destroy

        # delete user's profile 
        ProfilUser[:profil_id => old_profil.id, :user_id => user.id, :etablissement_id => etab.id].destroy  
        # set the new profile
        user.add_profil(etab.id, new_profil.id)
        ProfilUser[:user_id => user.id, :etablissement_id => etab.id, :profil_id => new_profil.id]   
      rescue  => e 
        puts e.message 
        error!("mouvaise requete", 400)
      end 
    end 
    

    ##################
    desc "Suppression d'un profil"
    params do 
      requires :id, type: Integer 
      requires :user_id, type: String 
      requires :profil_id , type: String 
    end 
    delete "/:id/profil_user/:user_id/:profil_id" do 
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      profil = Profil[:id => params[:profil_id]]
      error!("ressource non trouvee", 404) if profil.nil?
      begin
        # delete corresponding role
        RoleUser[:user_id => user.id, :role_id => profil.role_id].destroy
        # delete user's profile 
        ProfilUser[:profil_id => profil.id, :user_id => user.id, :etablissement_id => etab.id].destroy  
      rescue => e 
        puts e.message
        error!("mouvaise requete", 400)
      end
    end 


    ##########################
    # Gestion des parametres #
    ##########################

    #note: is it necessary to do the casting
    desc "Recupere la valeur d'un parametre precis"
    params do 
      requires :id, type: Integer 
      requires :app_id, type: String
      requires :code , type: String 
    end 
    get "/:id/parametre/:app_id/:code" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      app = Application[:id => params[:app_id]]
      error!("ressource non trouvee", 404) if app.nil?

      param_application = ParamApplication[:code => params[:code]]
      error!("ressource non trouvee", 404) if param_application.nil?
      begin 
        #etab.preferences(app.id)
        # if application belongs to etab
        if ApplicationEtablissement[:application_id => app.id, :etablissement_id => etab.id]
          parameter = etab.preferences(app.id, params[:code]) 
          # for the moment this returns the whole parameter object
          parameter[0]
        else
          error!("ressource non trouvee", 404) 
        end
      rescue => e
        puts e.message 
        error!("mouvaise requete", 400)
      end 
    end 
    
    ##################
    desc "Modifie la valeur d'un parametre"
    params do 
      requires :id, type: Integer 
      requires :app_id, type: String
      requires :code , type: String
      #requires :valeur, type: String
    end 
    put "/:id/parametre/:app_id/:code" do
      #puts params.inspect
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      app = Application[:id => params[:app_id]]
      error!("ressource non trouvee", 404) if app.nil?

      param_application = ParamApplication[:code => params[:code]]
      error!("ressource non trouvee", 404) if param_application.nil?
 
      begin
        id = param_application.id
        valeur = params[:valeur]
        etab.set_preference(id, valeur)
      rescue => e
        puts e.message  
        error!("mouvaise requete", 400)
      end 

    end

    ##################
    desc "Remettre la valeure par defaut du parametre"
    params do 
      requires :id, type: Integer 
      requires :app_id, type: String 
      requires :code , type: String
    end   
    delete "/:id/parametre/:app_id/:code" do 
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      app = Application[:id => params[:app_id]]
      error!("ressource non trouvee", 404) if app.nil?

      param_application = ParamApplication[:code => params[:code]]
      error!("ressource non trouvee", 404) if param_application.nil?
      begin
        id = param_application.id 
        etab.set_preference(id, nil) 
      rescue => e
        error!("mouvaise requete", 400) 
      end   
    end

    ##################
    desc "Recupere tous les parametres sur une application donnee"
    params do
      requires :id, type: Integer 
      requires :app_id, type: String  
    end 
    get "/:id/parametres/:app_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      app = Application[:id => params[:app_id]]
      error!("ressource non trouvee", 404) if app.nil?
      begin
        if ApplicationEtablissement[:application_id => app.id, :etablissement_id => etab.id]
          parameters = etab.preferences(app.id) 
          # for the moment this returns the whole parameter object
          parameters
        else
          error!("ressource non trouvee", 404) 
        end 

      rescue  => e 
        error!("mouvaise requete", 400)
      end 
    end

    ###################
    desc "Recupere tous les  parametres de l'etablissement" 
    params do 
      requires :id, type: Integer 
    end 
    get "/:id/parametres" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      begin
        parameters = []
        ApplicationEtablissement.filter(:etablissement_id => etab.id).each do |app_etab|
          temp  = etab.preferences(app_etab.application_id)
            temp.each do |param|
              parameters.push(param)
            end  
        end
        parameters     
      rescue => e
        error!("mouvaise requete", 400)
      end  
    end 


    ##########################################
    # Gestion de l'activation des parametres #
    ##########################################

    ###################
    #{"GED", "CAHIER_TXT"}
    desc "Gestion de l'activation des applications"
    params do 
      requires :id, type: Integer 
    end 
    get "/:id/application_actifs" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      begin
        DB[:application_etablissement].filter(:etablissement_id => etab.id).select(:application_id).all
      rescue => e 
        error!("mouvaise requete", 400)
      end 
    end

    ###################
    #{actif: true|false}
    desc "Activer ou desactiver une application"
    params do 
      requires :id , type: Integer 
      requires :app_id , type: String
      requires :actif , type: Boolean 
    end 
    put ":id/application_actifs/activer/:app_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      app = Application[:id => params[:app_id]]
      error!("ressource non trouvee", 400) if app.nil?
      activate = params[:actif]
      begin 
        if activate 
          ApplicationEtablissement.create(:etablissement_id => etab.id, :application_id => app.id)
        else 
          ApplicationEtablissement[:application_id => app.id, :etablissement_id => etab.id].destroy
        end 
      rescue => e 
        puts e.message 
        error!("mouvaise requete", 400)
      end  
    end 
 end

end

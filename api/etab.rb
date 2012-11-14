class EtabApi < Grape::API
  format :json 
  helpers do 
    def exclude_hash(params, excluded_items)
      parameters = params
      excluded_items.each do |item|
        parameters.delete(item)
      end
      return parameters
    end
  end   
    #################
    #{ "id": 1234, "nom": "Saint Honoré" }
    #res 200:
    #{ "id":  ... }
    desc "creer un etablissement"
    params do
      requires :code_uai, type: String
      requires :nom, type: String
      requires :type_etablissement, type: Integer
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
          if k != "route_info"
            begin
              if etab.respond_to?(k.to_sym)
                 etab.set(k.to_sym => v)
              end 
            rescue
              error!("Validation failed", 400)
            end
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
              puts e.message
              error!("Validation failed", 400)
            end
          end
        end
        etab.save()
      rescue Sequel::ValidationFailed
        error!("Validation failed", 400)
      end 
    end 


    #################
    #{role_id : "ADM_ETB"}
    desc "Assigner un role a quelqu'un"
    params do
      requires :id, type: Integer 
      requires :user_id, type: Integer 
      requires :role_id, type: String
    end  
    post "/:id/role_user/:user_id" do 
      # check if user is authorized to  change the role of an other user
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      role = Role[:id => params[:role_id]]
      error!("ressource non trouvee", 404) if role.nil?
      #authorize_activites!(ACT_CREATE, etab.ressource, SER_USER)


    end

    #################
    #{role_id : "PROF"}
    desc "Changer le role de quelqu'un"
    params do 
      requires :id, type: Integer 
      requires :user_id, type: Integer 
    end  
    put "/:id/role_user/:user_id" do
    end 

    #################
    desc "Supprimer son role sur l'etablissement"
    params do 
      requires :id, type: Integer
      requires :user_id, type: Integer
    end 
    delete "/:id/role_user/:user_id" do
    end  


=begin
    #################
    #{nom: "4°C", niveau: "4EME"}
    desc "creer une classe"
    params do 
      requires :id, type: Integer
    end 
    post "/:id/classe" do 
    end 

    #################
    #{nom: "4°D"}   
    desc "Modifier l'info d'un etab" 
    params do 
      requires :id, type: Integer
      requires :classe_id, type:Integer 
    end 
    put "/:id/classe/:classe_id" do 
    end 

    #################
    desc "Suppression d'une classe"
    params do 
      requires :id, type: Integer
      requires :classe_id, type: Integer
    end 
    delete "/:id/classe/:classe_id"  do 
    
    end 

    #################
    #{role_id : "PROF"}
    desc "Gestion des rattachement et des roles"
    params do 
      requires :id, type: Integer
      requires :classe_id, type: Integer
      requires :user_id, type: Integer
    end
    post "/:id/classe/:classe_id/role_user/:user_id" do
    end 
    
    #################
    desc "Dettachement"
    params do 
      requires :id, type: Integer
      requires :classe_id, type: Integer
      requires :user_id, type: Integer
    end
    delete "/:id/classe/:classe_id/role_user/:user_id" do 
    end

    ############### 
    #{matieres : ["FRANCAIS", "MATHEMATIQUES"]}
    desc "ajouter un enseigneant" 
    params do
      requires :id, type: Integer
      requires :classe_id, type: Integer
      requires :user_id, type: Integer 
    end 
    post "/:id/classe/:classe_id/enseigne/:user_id" do 
    end 
    
    ###############
    desc "Gestion des rattachements a un groupe libre"
    params do
      requires :id, type: Integer 
      requires :libre_id , type: Integer
    end
    post "/:id/libre/:libre_id/rattach" do 
    end 

    ################
    desc "supprimer un rattachement"
    params do
      requires :id, type: Integer 
      requires :libre_id , type: Integer
    end
    delete "/:id/libre/:libre_id/rattach" do 
    end 

    #################
    # []
    desc "Recuperer les niveaux pour cet etablissement" 
    params do 
      requires :id, type: Integer
    end 
    get "/:id/classe/niveaux" do 
    end 
    
    #################
    #{profil_id: "ELV"}
    desc "Ajout de profils utilisateur"
    params do 
      requires :id, type: Integer
      requires :user_id , type: Integer
    end  
    post "/:id/profil_user/:user_id" do 
    end   
    
    #################
    #{new_profil_id: "PROF", etablissement_id: 1234}
    desc "Modification d'un profil"
    params do  
      requires :id, type: Integer
      requires :user_id, type: Integer
      requires :old_profil_id, type: String
    end 
    put "/:id/profil_user/:user_id/:old_profil_id" do 
    end 
    

    ##################
    desc "Suppression d'un profil"
    params do 
      requires :id, type: Integer 
      requires :user_id, type: Integer 
      requires :profil_id , type: String 
    end 
    delete "/:id/profil_user/:user_id/:profil_id" do 
    end 

    ##Parametre d'établissement
    ##################
    desc "Recupere un parametre precis"
    params do 
      requires :id, type: Integer 
      requires :app_id, type: Integer
      requires :code , type: String 
    end 
    get  "/:id/parametre/:app_id/:code" do 
    end 
    
    ##################
    desc "Modifie un parametre"
    params do 
      requires :id, type: Integer 
      requires :app_id, type: Integer 
      requires :code , type: String
    end 
    put "/:id/parametre/:app_id/:code" do
    end

    ##################
    desc "Remettre la valeure par defaut du parametre"
    params do 
      requires :id, type: Integer 
      requires :app_id, type: Integer 
      requires :code , type: String
    end   
    delete "/:id/parametre/:app_id/:code" do 
    end

    ##################
    desc "Recupere tous les parametres sur une application donne"
    params do
      requires :id, type: Integer 
      requires :app_id, type: Integer  
    end 
    get "/:id/parametres/:app_id" do 
    end

    ###################
    desc "Recupere tous les  parametres de l'etablissement" 
    params do 
      requires :id, type: Integer 
    end 
    get "/:id/parametres" do 
    end 

    ###################
    #{"GED": true, "CAHIER_TXT": false}
    desc "Gestion de l'activation des applications"
    params do 
      requires :id, type: Integer 
    end 
    get "/:id/application_actifs" do
    end

    ###################
    #{actif: true|false}
    desc "Activer ou desactiver une application"
    params do 
      requires :id , type: Integer 
      requires :app_id , type: Integer
    end 
    put ":id/services_actifs/:service_id" do 
    end 
=end  

end

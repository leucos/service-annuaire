class EtabApi < Grape::API
  format :json

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
    #################
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
      puts "POST"
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
      puts "update api "
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


    #################
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
        puts e.message
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
        puts e.message
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
        puts e.message
        error!("Validation Failed", 400)
      end
    end  


    #################
    #{nom: "4°C", niveau: "4EME"}
    desc "creer une classe"
    params do 
      requires :id, type: Integer
    end 
    post "/:id/classe" do 
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      begin

      rescue => e 
      end 
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

=begin
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

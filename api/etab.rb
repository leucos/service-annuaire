#coding: utf-8
require 'grape-swagger'
class EtabApi < Grape::API
  prefix 'api'
  version 'v1', :using => :param, :parameter => "v"
  format :json
  #content_type :json, "application/json; charset=utf-8"
  default_error_formatter :json
  default_error_status 400

  # Tout erreur de validation est gérée à ce niveau
  # Va renvoyer le message d'erreur au format json
  # avec le default error status
  rescue_from :all

  helpers RightHelpers 
  helpers SearchHelpers

  helpers do 
    def exclude_hash(params, excluded_items)
      parameters = params
      excluded_items.each do |item|
        parameters.delete(item)
      end
      return parameters
    end

    def modify_user(user)
      # Use the declared helper
      declared(params, include_missing: false).each do |k,v|
        user.set(k.to_sym => v)
      end

      user.save()
    end

    def check_email!(user, email)
      error!("Email non trouvé", 404) if !user.has_email(email.adresse)
    end

  end
  before do
    authenticate! 
  end

  resource :etablissements do

  ##############################################################################
  #             Gestion de l'etablissement (CRUD)                              #
  ##############################################################################

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
      authorize_activites!([ACT_CREATE, ACT_MANAGE], Ressource.laclasse, SRV_ETAB)
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

    ##############################################################################
    desc "return etablissement details"
    params do
      requires :id, type: String
      optional :expand, type:String, desc: "show simple or detailed info, value = true or false"
    end  
    get "/:id" do
      etab = Etablissement[:code_uai => params[:id]]
      #authorize_activites!(ACT_READ,etab.ressource)
      # construct etablissement entity.
      if !etab.nil?
        authorize_activites!([ACT_READ, ACT_MANAGE], etab.ressource) 
        if params[:expand] == "true"
          present etab, with: API::Entities::DetailedEtablissement
        else 
          response = present etab, with: API::Entities::SimpleEtablissement
          JSON.pretty_generate(response)
       end
      else
        error!("ressource non trouve", 404) 
      end 
    end

    ##############################################################################
    desc "Modifier l'info d'un etablissement"
    params do
      requires :id , type: String
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
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource nont trouvee", 404) if etab.nil?
      
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], etab.ressource)

      parameters = exclude_hash(params, ["id", "route_info", "session"])
      #authorize_activites!(ACT_UPDATE,etab.ressource)
      begin
        parameters.each do |k,v|
          if k != "route_info" or k != "session"
            begin
              if etab.respond_to?(k.to_sym) && etab.columns.include?(k.to_sym)
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

    ##############################################################################
    desc "Supprimer un etablissement"
    params do 
      requires :id, type:String
    end
    delete "/:id" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource nont trouvee", 404) if etab.nil?
      authorize_activites!([ACT_DELETE, ACT_MANAGE], etab.ressource)
      etab.destroy
    end  

    ##############################################################################
    desc "Upload an image(logo)"
    params do 
      requires :id, type:String
    end 
    post "/:id/upload/logo" do
      #puts params.inspect
      etab = Etablissement[:code_uai => params[:id]]
      if etab 
        tempfile = params[:image][:tempfile]
        imagetype = params[:image][:type].split("/")[1]

        # read received file and write it to public folder
        File.open(tempfile.path, 'rb') do |input| 
          File.open("public/api/logos/banniere_etab_#{params[:id]}.#{imagetype}", 'wb') {|out| out.write(input.read) }
        end

        etab.logo = "banniere_etab_#{params[:id]}.#{imagetype}"
        etab.save 
        #puts "logo saved"
        {
          etablissemnt: params[:id],
          filename: "banniere_etab_#{params[:id]}.#{imagetype}",
          size: params[:image][:tempfile].size,
          type: imagetype
        }
      else 
        error!("etablissement non trouve", 404)
      end   
  
    end

    ##############################################################################
    #                    Gestion des utilisateurs                                #
    ##############################################################################
    desc "get the list of users in an etablissement and search users in the etablissement" 
    params do 
      requires :id, type: String
      optional :query, type: String, desc: "pattern de recherche. Possibilité de spécifier la colonne sur laquelle faire la recherche ex: 'nom:Chackpack prenom:Georges'"
      optional :limit, type: Integer, desc: "Nombre maximum de résultat renvoyés"
      optional :page, type: Integer, desc: "Dans le cas d'une requète paginée"
      optional :sort_col, type: String, desc: "Nom de la colonne sur laquelle faire le tri"
      optional :sort_dir, type: String, regexp: /^(asc|desc)$/i, desc: "Direction de tri : ASC ou DESC"
      optional :all, type:Boolean
      group :advanced do
        optional :prenom, type: String
        optional :nom, type: String
        optional :login, type: String
        optional :etablissement, type: String, desc: "Nom de l'établissement dans lequel est l'utilisateur"
        optional :user_id, type: String
      end 
    end
    get "/:id/users" do
      etab = Etablissement[:code_uai => params[:id]]
      authorize_activites!([ACT_READ, ACT_MANAGE], etab.ressource, SRV_USER)
      accepted_fields = {
        prenom: :prenom, nom: :user__nom, login: :login, etablissement: :etablissement__nom, id: :user__id, 
        id_ent: :id_ent, profil_id: :profil_user__profil_id, profil: :profil_national__description, regroupement_id: :regroupement__libelle_aaf
      }

      dataset = User.search_all_dataset()
      dataset = dataset.where(:etablissement__code_uai => params[:id])
      if params[:all]
        dataset.select(:user__nom, :prenom, :id_ent,:user__id, :profil_user__profil_id, :profil_national__description).naked.all
      else 
        results = super_search!(dataset, accepted_fields)
        results
      end 
    end
    
    ##############################################################################    
    desc "get user infon in the etablissement"
    params do 
      requires :id, type:String
      requires :user_id, type:String 
      #optional :expand, type:Boolean
    end

    get "/:id/users/:user_id"  do 
      etab = Etablissement[:code_uai => params[:id]]
      user = User[:id_ent => params[:user_id]]
      authorize_activites!([ACT_READ, ACT_MANAGE], user.ressource)
       if params[:expand] == "true"
        present user, with: API::Entities::DetailedUser
      else 
        present user, with: API::Entities::SimpleUser
      end
    end 
    ##############################################################################

    desc "Create user in the etablissement"
    params do
      requires :id, type:String
      requires :login, type: String, desc: "Doit commencer par une lettre et ne pas comporter d'espace"
      requires :password, type: String
      requires :nom, type: String
      requires :prenom, type: String
      requires :profil, type: String
      optional :sexe, type: String, desc: "Valeurs possibles : F ou M"
      optional :date_naissance, type: Date
      optional :adresse, type: String
      optional :code_postal, type: Integer, desc: "Ne doit comporter que 6 chiffres" 
      optional :ville, type: String
      optional :id_sconet, type: Integer
      optional :id_jointure_aaf, type: Integer
    end 
    post "/:id/users" do 
      begin
        etab = Etablissement[:code_uai => params[:id]]
        authorize_activites!([ACT_CREATE, ACT_MANAGE], etab.ressource,SRV_USER)

        user = User.new
        #modify_user(user)
        
        declared(params, include_missing: false).each do |k,v|
          if k.to_sym != :id && user.respond_to?(k.to_sym)  
              user.set(k.to_sym => v)
          end   
        end
        user.save()
        user.add_profil(etab.id, params[:profil])
        present user, with: API::Entities::SimpleUser
      rescue => e 
        error!(e.message, 400)
      end  
    end

    ##############################################################################
    desc "Modify user info in the (etablissemnt)"
    params do 
      optional :login, type: String, desc: "Doit commencer par une lettre et ne pas comporter d'espace"
      optional :password, type: String
      optional :nom, type: String
      optional :prenom, type: String
      optional :sexe, type: String, desc: "Valeurs possibles : F ou M"
      optional :date_naissance, type: Date
      optional :adresse, type: String
      optional :code_postal, type: Integer, desc: "Ne doit comporter que 6 chiffres" 
      optional :ville, type: String
      optional :id_sconet, type: Integer
      optional :id_jointure_aaf, type: Integer
      optional :bloque, type:Boolean
    end
    put "/:id/users/:user_id" do
      begin
        etab = Etablissement[:code_uai => params[:id]]
        user = User[:id_ent => params[:user_id]]
        authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)
        declared(params, include_missing: false).each do |k,v|
          if k.to_sym != :id && user.respond_to?(k.to_sym)  
              user.set(k.to_sym => v)
          end   
        end
        user.save()
        present user, with: API::Entities::SimpleUser  
      rescue => e
        error!(e.message, 400)
      end   
    end

    ##############################################################################
    desc "Delete a user from the etablissement"
    delete "/:id/users/:user_id" do 
      begin 
        etab = Etablissement[:code_uai => params[:id]]
        user = User[:id_ent => params[:user_id]]
        authorize_activites!([ACT_DELETE, ACT_MANAGE], user.ressource) 
        user.destroy
      rescue => e
        error!(e.message, 400)
      end  
    end

    ##############################################################################
    desc "Delete a list of users from the etablissement"
    delete "/:id/users/list/:ids" do 
      begin 
        # transform checked to JSON
        checked_users = JSON.parse(params[:checked])
        #puts checked_users.inspect
        etab = Etablissement[:code_uai => params[:id]]
        checked_users.each do |item|
          if item["val"] == true
            user = User[:id => item["id"]]
            #puts user  
            if user
              authorize_activites!([ACT_DELETE, ACT_MANAGE], user.ressource)  
              #puts "#{user.nom} user will be delete"
              user.destroy
            end # end loop
          end 
        end # end loop
        "ok"     
      rescue => e
        error!(e.message, 400)
      end 
    end 
    ##############################################################################
    desc "get the list of (eleves libres) which are not in any class"
    params do 
      requires :id, type:String 
      # ce parametre retourne les eleves qui n'appartienne pas à une classe
      optional :libre, type:String
      # exclude eleves that belongs to a certain groupe or class
      optional :exclude, type:Integer  
    end 
    get "/:id/eleves" do 
      etab = Etablissement[:code_uai => params[:id]]
      authorize_activites!([ACT_READ, ACT_MANAGE], etab.ressource, SRV_USER)
      if params[:libre]== "true" 
        JSON.pretty_generate(etab.eleves_libres)
      elsif params[:exclude]
        JSON.pretty_generate(etab.eleves_exclude(params[:exclude])) 
      else 
        JSON.pretty_generate(etab.eleves)
      end 
    end 

    ###############################################################################
    desc "get the list of (profs) in (Etablissement)"
    params do 
      requires :id, type:String 
    end 
    get "/:id/profs" do 
      etab = Etablissement[:code_uai => params[:id]]
      authorize_activites!([ACT_READ, ACT_MANAGE], etab.ressource, SRV_USER)
      JSON.pretty_generate(etab.enseignants)
    end

    ################################################################################
    # get all etablissements and  add search capability to that
    desc "get la liste des etablissements and search"
    params do
      optional :query, type: String, desc: "pattern de recherche. Possibilite de specifier la colonne sur laquelle faire la recherche ex: 'nom:college code_postal:69000'"
      optional :limit, type: Integer, desc: "Nombre maximum de resultat renvoyes"
      optional :page, type: Integer, desc: "Dans le cas d'une requete paginee"
      optional :sort_col, type: String, desc: "Nom de la colonne sur laquelle faire le tri"
      optional :sort_dir, type: String, regexp: /^(asc|desc)$/i, desc: "Direction de tri : ASC ou DESC"
      optional :all, type: Boolean, desc:"if all is set to true, return all etablissmenets"
      group :advanced do
        optional :type_etablissement, type: Integer
        optional :code_uai, type: String
        optional :adresse, type: String
        optional :nom, type: String, desc: "Nom de l'etablissement"
      end
    end
    get  do
      authorize_activites!([ACT_READ, ACT_MANAGE], Ressource.laclasse, SRV_ETAB)
      accepted_fields = {
        nom: :nom, code_uai: :code_uai, adresse: :adresse, type_etablissement_id: :type_etablissement_id
      }

      ds = DB[:etablissement]
      #dataset = ds.all
      dataset = Etablissement.dataset

      # return all etablissements 
      if params[:all] == true
        dataset.select(:id, :code_uai, :nom).naked
      else 
        if params[:query]
          patterns = split_query(params[:query])
          dataset = apply_filter!(patterns, dataset, accepted_fields)
        end

        column = params[:sort_col]
        direction = params[:sort_dir]
        if column
          dataset = apply_sort!(column, direction, dataset, accepted_fields)
        elsif direction
          error!("Direction de tri définit sans colonne (sort)", 400)
        end

        # todo : Limit arbitraire de 500, gérer la limit max en fonction du profil ?
        page_size = params[:limit] ? params[:limit] : 500
        page_no = params[:page] ? params[:page] : 1

        dataset = dataset.paginate(page_no, page_size)
        data = dataset.collect{ |x| {
          :id => x.id, 
          :classes => x.classes, 
          :code_uai => x.code_uai, 
          :nom => x.nom,
          :adresse => x.adresse,
          :code_postal  => x.code_postal,
          :ville => x.ville, 
          :type_etablissement_id => x.type_etablissement_id,
          :telephone => x.telephone, 
          :fax => x.fax , 
          :site_url => x.site_url,
          :alimentation_state => x.alimentation_state,
          :alimentation_date => x.alimentation_date,
          :last_alimentation => x.last_alimentation, 
          :longitude => x.longitude,
          :latitude => x.latitude , 
          :contacts => x.contacts,
          :groupes_eleves => x.groupes_eleves,
          :personnel => x.personnel, 
          :eleves => x.eleves, 
          :enseignants => x.enseignants
          }
        }        
        {total: dataset.pagination_record_count, page: page_no, data: data}
      end 
    end   

    ##############################################################################
    #             Gestion des roles dans l'etablissement                         #
    ##############################################################################
    desc "Return Roles in Etablissement"
    params do 
      requires :id, type:String
    end
    get "/:id/roles" do
      etab = Etablissement[:code_uai => params[:id]]
      authorize_activites!([ACT_READ, ACT_MANAGE], etab.ressource, SRV_ROLE)
      Role.where('priority <= ?', 2) 
    end    

    #Note: use authorize
    #{role_id : "ADM_ETB"}
    desc "Assigner un role à un utilisateur"
    params do
      requires :id, type: String
      requires :user_id, type: String 
      requires :role_id, type: String
    end  
    post "/:id/users/:user_id/role_user" do 
      # check if user is authorized to  change the role of an other user
      #authorize_activites!(ACT_CREATE, etab.ressource)
      etab = Etablissement[:code_uai => params[:id]]
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], etab.ressource, SRV_USER)
      authorize_activites!([ACT_CREATE, ACT_MANAGE], etab.ressource, SRV_ROLE)
      error!("ressource non trouvee", 404) if etab.nil?
      user = User[:id_ent => params[:user_id]]
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
        #ressource = etab.ressource
        user.add_role(etab.id, role.id)  
      rescue => e
        #puts e.message
        error!("Validation Failed", 400)
      end
      {:user_id => user.id, :user_role => role.id}     
    end


    desc "Assigner un role à plusieurs  utilisateurs"
    params do 
      requires :checked
    end 
    post "/:id/users/roles/:role_id" do
      puts params[:checked].inspect 
      etab = Etablissement[:code_uai => params[:id]]
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], etab.ressource, SRV_USER)
      authorize_activites!([ACT_CREATE, ACT_MANAGE], etab.ressource, SRV_ROLE)
      error!("ressource non trouvee", 404) if etab.nil?
      role = Role[:id => params[:role_id]]
      error!("ressource non trouvee", 404) if role.nil?
      begin 
        # transform checked to JSON
        checked_users = JSON.parse(params[:checked])
        checked_users.each do |item|
          if item["val"] == true
            user = User[:id => item["id"]]
            #puts user  
            if user
              authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)  
              puts "#{user.nom} user have a role #{role.id}"
              user.add_role(etab.id, role.id)
            end # end loop
          end 
        end # end loop
        "ok"     
      rescue => e
        error!(e.message, 400)
      end
      
    end 

    ##############################################################################
    desc "Changer le role de quelqu'un"
    params do 
      requires :id, type: String
      requires :user_id, type: String
      requires :old_role_id, type: String
      requires :role_id, type:String 
    end  
    put "/:id/users/:user_id/role_user/:old_role_id" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], etab.ressource, SRV_USER)
      authorize_activites!([ACT_CREATE, ACT_MANAGE], etab.ressource, SRV_ROLE)

      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      old_role = Role[:id => params[:old_role_id]]
      error!("ressource non trouvee", 404) if old_role.nil?
      new_role = Role[:id => params[:role_id]]
      error!("ressource non trouvee", 404) if new_role.nil?
      begin 
        role_user = RoleUser[:etablissement_id => etab.id, :role_id => old_role.id, :user_id => user.id]
        if role_user 
          role_user.destroy
        end 
        user.add_role(etab.id, new_role.id)
      rescue => e
        #puts e.message
        error!("Validation Failed", 400)
      end
      {:user_id => user.id, :user_role => new_role.id} 
    end 

    ##############################################################################
    desc "Supprimer un role de l'utilisateur dans l'etablissement"
    params do 
      requires :id, type: String
      requires :user_id, type: String
      requires :role_id, type: String 
    end 
    delete "/:id/users/:user_id/role_user/:role_id" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], etab.ressource, SRV_USER)
      authorize_activites!([ACT_DELETE, ACT_MANAGE], etab.ressource, SRV_ROLE)
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      role = Role[:id => params[:role_id]]
      error!("ressource non trouvee", 404) if role.nil?
      begin 
        role_user = RoleUser[:user_id => user.id, :etablissement_id => etab.id, :role_id => role.id]
        role_user.destroy if role_user
      rescue => e
        error!("Validation Failed", 400)
      end
    end


    ##############################################################################
    #                         Gestion des classes                                #
    ##############################################################################
    desc "list all classes in the etablissement"
    params do 
      requires :id, type: String
    end
    get "/:id/classes" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_READ, ACT_MANAGE], etab.ressource, SRV_CLASSE)
      begin
        JSON.pretty_generate(etab.classes)
      rescue => e
        error!("mouvaise requete", 400) 
      end 
    end 

    ##############################################################################
    #@input: {libelle: "4°C", code_mef_aaf: "4EME"}
    #@output: {classe.id }
    desc "creer une classe dans l'etablissement"
    params do 
      requires :id, type: String
      requires :libelle, type: String
      requires :code_mef_aaf, type: String
      optional :description,  type:String 
    end 
    post "/:id/classes" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_CREATE, ACT_MANAGE], etab.ressource, SRV_CLASSE)
      parameters = exclude_hash(params, ["id", "route_info", "session", "session_key"])
      begin
          classe = etab.add_classe(parameters)
          classe
      rescue => e
        puts e.message 
        error!("mouvaise requete", 400) 
      end 
    end 
    
   ##############################################################################
    #@input{libelle: "4°D"}   
    desc "Modifier l'info d'une classe" 
    params do 
      requires :id, type: String
      requires :classe_id, type:Integer 
    end 
    put "/:id/classes/:classe_id" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], etab.ressource, SRV_CLASSE)
      
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], classe.ressource)

      parameters = exclude_hash(params, ["id", "route_info", "session", "classe_id"])
      begin 
        parameters.each do  |k,v| 
          if classe.respond_to?(k.to_sym)
            classe.set(k.to_sym => v) 
          end    
        end
        classe.save 
      rescue  => e       
        error!("mouvaise request", 400) 
      end 
    end 
    
    ##############################################################################
    # Types of responses depending on expand params
    # => Simple: ex. {"id":1,"etablissement_id":4813,"libelle":null,"libelle_aaf":"6A","type_regroupement_id":"CLS"}
    # => Detailed: ex. {"id":1,"etablissement_id":4813,"libelle":null,"libelle_aaf":"6A","type_regroupement_id":"CLS",
    #   "profs":[{"id":467,"id_ent":"VAA60466","id_jointure_aaf":22184,"nom":"BERNARD","prenom":"Nathalie"},..], 
    #   "eleves":[{"id":457,"id_sconet":1038997,"id_ent":"VAA60456","id_jointure_aaf":2417366,"nom":"WERNER","prenom":"Florent"},..]}

    desc "get l'info d'une classe"
    params do 
      requires :id, type: String
      requires :classe_id, type:Integer
      optional :expand, type:String, desc: "show simple or detailed info, value = true or false"
    end 
    get "/:id/classes/:classe_id" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("pas de droit", 403) if classe.etablissement_id != etab.id

      authorize_activites!([ACT_READ, ACT_MANAGE], classe.ressource)
      if params[:expand] == "true"
        present classe, with: API::Entities::DetailedRegroupement
      else
        present classe, with: API::Entities::SimpleRegroupement   
      end  
    end 

    ##############################################################################
    desc "Suppression d'une classe"
    params do 
      requires :id, type: String
      requires :classe_id, type: Integer
    end 
    delete "/:id/classes/:classe_id"  do   
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_DELETE, ACT_MANAGE], etab.ressource, SRV_CLASSE)

      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      authorize_activites!([ACT_DELETE, ACT_MANAGE], classe.ressource)
      begin
        Regroupement[:id => classe.id].destroy
      rescue  => e
        error!("mouvaise request", 400) 
      end 
    end

    ##############################################################################
    # Rattachement d'un eleve ou prof à une classe
    desc "rattachements d'un eleve à une classe"
    params do 
      requires :id, type: String
      requires :classe_id, type: Integer
      requires :user_id, type: String
    end
    post "/:id/classes/:classe_id/eleves/:user_id" do
      # role ou profil
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("mouvaise requete", 400) if classe.type_regroupement_id!='CLS'
      error!("pas de droit", 403) if classe.etablissement_id != etab.id
      
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      authorize_activites!([ACT_UPDATE, ACT_MANAGE], classe.ressource)
      begin
        # user has profil eleve 
        if user.profil_user_dataset.where(:profil_id=>'ELV').count == 1 
          EleveDansRegroupement.find_or_create(:user_id => user.id,:regroupement_id => classe.id)
        end 
        #ressource = classe.ressource
        #user.add_role(ressource.id, ressource.service_id, role.id)
      rescue => e 
        puts e.message
        error!("mouvaise requete", 400)
      end    
    end

    ##############################################################################
    # Rattachement d'un eleve ou prof à une classe
    desc "Detachement d'un eleve d'une classe"
    params do 
      requires :id, type: String
      requires :classe_id, type: Integer
      requires :user_id, type: String
    end
    delete "/:id/classes/:classe_id/eleves/:user_id" do
      # role ou profil
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("mouvaise requete", 400) if classe.type_regroupement_id!='CLS'
      error!("pas de droit", 403) if classe.etablissement_id != etab.id
      
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      begin
        # user has profil eleve 
        if user.profil_user_dataset.where(:profil_id=>'ELV').count == 1 
          EleveDansRegroupement[:user_id => user.id, :regroupement_id => classe.id].delete
        end 
      rescue => e 
        puts e.message
        error!("mouvaise requete", 400)
      end    
    end
    ##############################################################################
    #          Gestion des rattachement et des roles dans une classe             #
    ##############################################################################

    # add  a profil
    # what type of profil/role
    # may change the 
    #{role_id : "PROF"}
    desc "Gestion des rattachements et des roles"
    params do 
      requires :id, type: Integer
      requires :classe_id, type: Integer
      requires :user_id, type: String
      requires :role_id, type: String 
    end
    post "/:id/classes/:classe_id/role_user/:user_id" do
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

    ##############################################################################

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
    
    ##############################################################################
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

    ##############################################################################
    #{matieres ids : [200, 300]}
    desc "Lister les enseignants dans une classe" 
    params do
      requires :id, type: String
      requires :classe_id, type: Integer
      optional :notin, type: String 
    end 
    get "/:id/classes/:classe_id/profs" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("pas de droit", 403) if classe.etablissement_id != etab.id
     
      begin 
        if params[:notin] == "true" 
          etab.enseignants.select{|prof|  !classe.profs.map{|x| x[:id_ent]}.include?(prof[:id_ent])}
        else
          classe.profs
        end 
      rescue  => e 
        puts e.message
        error!("mouvaise requete", 400)
      end 
    end

    ##############################################################################

    #{matieres ids : [200, 300]}
    desc "Ajouter un enseignant et ajouter des matieres" 
    params do
      requires :id, type:String
      requires :classe_id, type: Integer
      requires :user_id, type: String
      optional :matiere, type:String
    end 
    post "/:id/classes/:classe_id/profs/:user_id" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?
      error!("pas de droit", 403) if classe.etablissement_id != etab.id
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      matiere = params[:matiere]
      if matiere 
         mat_id = matiere
      else 
        # matiere par defaut
        mat_id = "003700"
      end 
      begin
        classe.add_prof(user, mat_id)
        # if user exists => add matieres else add prof
        #ens_mat = EnseigneDansRegroupement[:user_id => user.id, :regroupement_id => classe.id, :matiere_enseignee_id => mat_id] 
        #if ens_mat

            # for the moment do nothing, matiere enseignee id needs to be changed to 
            # a primary key 

            #matieres.each do |mat|
              #ens_mat.regroupement = classe
              #ens_mat.user_id = user.id     
              #ens_mat.matiere_enseignee_id = mat
              #ens_mat.save 
            #end 
        #else
          #classe.add_prof(user, matiere)
          #EnseigneDansRegroupement.create(:user_id => user.id, :regroupement_id => classe.id, :matiere_enseignee_id => mat_id)
        #end 
      rescue  => e 
        puts e.message
        error!("mouvaise requete", 400)
      end 
    end

    ##############################################################################
    desc "supprimer un enseignant"
    params do 
      requires :id, type: String
      requires :classe_id, type: Integer
      requires :user_id, type: String
      optional :matiere, type:String
    end

    delete "/:id/classes/:classe_id/profs/:user_id" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      classe = Regroupement[:id => params[:classe_id]]
      error!("ressource non trouvee", 404) if classe.nil?      
      error!("pas de droit", 403) if classe.etablissement_id != etab.id
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      begin
        # delete user role as prof
        # RoleUser[:user_id => user.id, :role_id => "PROF_CLS", :ressource_id => classe.ressource.id].destroy

        # delete all (matieres)
        # EnseigneDansRegroupement.filter(:user_id => user.id, :Regroupement_id => classe.id).each {|mat| mat.destroy}
        if params[:matiere]
          #delete matiere  with prof
          EnseigneDansRegroupement.filter(:user_id => user.id, :Regroupement_id => classe.id, :matiere_enseignee_id => params[:matiere]).destroy
        else
          #delete prof completely
          EnseigneDansRegroupement.filter(:user_id => user.id, :Regroupement_id => classe.id).destroy
        end 
      rescue => e
        puts e.message 
        error!("mouvaise requete", 400)
      end    
    end 

    ##############################################################################
    desc "supprimer une matieres"
    params do 
      requires :id, type: Integer
      requires :classe_id, type: Integer
      requires :user_id, type: String
      requires :matiere_id, type: Integer
    end
    delete "/:id/classe/:classe_id/profs/:user_id/matieres/:matiere_id" do
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
        EnseigneDansRegroupement.filter(:user_id => user.id, :Regroupement_id => classe.id, :matiere_enseignee_id => matiere_id).each {|mat| mat.destroy}
      rescue => e 
        puts e.message 
        error!("mouvaise requete", 400)
      end
    end  

    ##############################################################################
      desc "lister les matieres enseignees dans letablissement"
      params do 
        requires :id, type: String
        optional :query, type:String # values all or exculde
        # all: toutes les matieres de l'academie
        # exclude: toutes les matieres non enseignées dans l'etablissement
      end
      get "/:id/matieres" do
        if params[:query].nil? # retourner les matieres enseignées dans l'etablissement
          etab = Etablissement[:code_uai => params[:id]]
          JSON.pretty_generate(etab.matieres)
        elsif params[:query] == "all"
          JSON.pretty_generate(MatiereEnseignee.naked.all)
        elsif params[:query] == "exclude"
          etab = Etablissement[:code_uai => params[:id]]
          JSON.pretty_generate(MatiereEnseignee.exclude_where(:id => etab.matieres.collect{|mat| mat[:id]}).naked.all)
        end
      end 
 
    ##############################################################################
    #                     Gestion des groupes d'eleves                           #
    ##############################################################################
    
    desc "lister les groupes d'éléve dans l'etablissement"
    params do 
      requires :id, type:String
    end 
    get "/:id/groupes" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_READ, ACT_MANAGE], etab.ressource, SRV_GROUPE)
      JSON.pretty_generate(etab.groupes_eleves)
    end

    ##############################################################################

    desc "Retourner les infos d'un groupe d'eleve"
    params do 
      requires :id, type:String
      requires :groupe_id, type:Integer
    end 
    get "/:id/groupes/:groupe_id" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      groupe = Regroupement[:id => params[:groupe_id]]
      error!("pas de droit", 403) if groupe.etablissement_id != etab.id
      authorize_activites!([ACT_READ, ACT_MANAGE], groupe.ressource)
      if params[:expand] == "true"
        present groupe, with: API::Entities::DetailedRegroupement
      else
        present groupe, with: API::Entities::SimpleRegroupement   
      end 
    end

    ##############################################################################

    desc "creer un groupe d'eleve"
    params do 
      requires :id, type: String
      requires :libelle, type: String
      optional :niveau_id, type: String 
      optional :description, type: String 
    end 
    post "/:id/groupes" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_CREATE, ACT_MANAGE], etab.ressource, SRV_GROUPE)
      parameters = exclude_hash(params, ["id", "route_info", "session", "session_key"])
      begin
          groupe = etab.add_groupe_eleve(parameters)
          groupe
      rescue => e
        error!("mauvaise requete", 400) 
      end 
    end 

   ##############################################################################
    #@input{libelle: "4°D"}   
    desc "Modifier l'info d'un groupe d'eleve" 
    params do 
      requires :id, type: String
      requires :groupe_id, type:Integer 
    end 
    put "/:id/groupes/:groupe_id" do 
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], etab.ressource, SRV_GROUPE)

      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil?
      authorize_activites!([ACT_CREATE, ACT_MANAGE], groupe.ressource)
      
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

    ##############################################################################
    desc "Suppression d'un groupe"
    params do 
      requires :id, type:String
      requires :groupe_id, type: Integer
    end 
    delete "/:id/groupes/:groupe_id"  do   
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_DELETE, ACT_MANAGE], etab.ressource, SRV_GROUPE)
      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if  groupe.nil?
      authorize_activites!([ACT_DELETE, ACT_MANAGE], groupe.ressource) 
      error!("pas de droit", 403) if groupe.etablissement_id != etab.id
      begin
        Regroupement[:id => groupe.id].destroy
      rescue  => e
        error!("mouvaise requete", 400)  
      end 
    end

    ##############################################################################
    ##          gestion d'un role dans un groupe                                ##
    ##############################################################################
    ##            Gestion des prof dans un group                                ##

    desc "Retournez la liste des prof dans un groupe"
    params do 
      requires :id, type:String
      requires :groupe_id, type:Integer
    end 
    get "/:id/groupes/:groupe_id/profs" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil?
      error!("pas de droit", 403) if groupe.etablissement_id != etab.id

      groupe.profs
    end

    ##############################################################################
    desc "Ajouter un enseignant et ajouter des matieres à un groupe" 
    params do
      requires :id, type:String
      requires :groupe_id, type: Integer
      requires :user_id, type: String
      optional :matiere, type:String
    end 
    post "/:id/groupes/:groupe_id/profs/:user_id" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil?
      error!("pas de droit", 403) if groupe.etablissement_id != etab.id
      
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      
      matiere = params[:matiere]
      if matiere 
         mat_id = matiere
      else 
        # matiere par defaut
        mat_id = "003700"
      end 
      begin
        groupe.add_prof(user, mat_id)
      rescue  => e 
        puts e.message
        error!("mouvaise requete", 400)
      end 
    end

    ##############################################################################
    desc "supprimer un enseignant d'un groupe"
    params do 
      requires :id, type: String
      requires :groupe_id, type: Integer
      requires :user_id, type: String
      optional :matiere, type:String
    end

    delete "/:id/groupes/:groupe_id/profs/:user_id" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil?      
      error!("pas de droit", 403) if groupe.etablissement_id != etab.id
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      begin
        # delete user role as prof
        # RoleUser[:user_id => user.id, :role_id => "PROF_CLS", :ressource_id => classe.ressource.id].destroy

        # delete all (matieres)
        # EnseigneDansRegroupement.filter(:user_id => user.id, :Regroupement_id => classe.id).each {|mat| mat.destroy}
        if params[:matiere]
          #delete matiere  with prof
          EnseigneDansRegroupement.filter(:user_id => user.id, :Regroupement_id => groupe.id, :matiere_enseignee_id => params[:matiere]).destroy
        else
          #delete prof completely
          EnseigneDansRegroupement.filter(:user_id => user.id, :Regroupement_id => groupe.id).destroy
        end 
      rescue => e
        error!("mouvaise requete", 400)
      end    
    end 

    ##############################################################################
    desc "retourner la liste des eleves dans un groupe"
    params do 
    end 
    get "/:id/groupes/:groupe_id/eleves" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil?      
      error!("pas de droit", 403) if groupe.etablissement_id != etab.id
      begin 
        groupe.eleves
      rescue => e 
        error!(e.message, 400)
      end 

    end 

    ##############################################################################
    desc "supprimer une matieres liée à un prof d'un groupe"
    params do 
      requires :id, type: Integer
      requires :groupe_id, type: Integer
      requires :user_id, type: String
      requires :matiere_id, type: Integer
    end
    delete "/:id/groupes/:groupe_id/profs/:user_id/matieres/:matiere_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil?      
      error!("pas de droit", 403) if groupe.etablissement_id != etab.id
      user = User[:id => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      matiere_id = params[:matiere_id]
      begin
        # delete all (matieres)
        EnseigneDansRegroupement.filter(:user_id => user.id, :Regroupement_id => groupe.id, :matiere_enseignee_id => matiere_id).each {|mat| mat.destroy}
      rescue => e 
        puts e.message 
        error!("mouvaise requete", 400)
      end
    end  

    ##############################################################################
    # => Rattachement d'un eleve à un groupe 
    desc "rattachements d'un eleve à un groupe"
    params do 
      requires :id, type: String
      requires :groupe_id, type: Integer
      requires :user_id, type: String
    end
    post "/:id/groupes/:groupe_id/eleves/:user_id" do
      # role ou profil
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil?
      error!("mouvaise requete", 400) if groupe.type_regroupement_id!='GRP'
      error!("pas de droit", 403) if groupe.etablissement_id != etab.id
      
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      begin
        # user has profil eleve 
        if user.profil_user_dataset.where(:profil_id=>'ELV').count == 1 
          EleveDansRegroupement.find_or_create(:user_id => user.id,:regroupement_id => groupe.id)
        end 
        #ressource = classe.ressource
        #user.add_role(ressource.id, ressource.service_id, role.id)
      rescue => e 
        puts e.message
        error!("mouvaise requete", 400)
      end    
    end

    ##############################################################################
    desc "Detachement d'un eleve d'une classe"
    params do 
      requires :id, type: String
      requires :groupe_id, type: Integer
      requires :user_id, type: String
    end
    delete "/:id/groupes/:groupe_id/eleves/:user_id" do
      # role ou profil
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil?
      error!("mouvaise requete", 400) if groupe.type_regroupement_id!='GRP'
      error!("pas de droit", 403) if groupe.etablissement_id != etab.id
      
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      begin
        # user has profil eleve 
        if user.profil_user_dataset.where(:profil_id=>'ELV').count == 1 
          EleveDansRegroupement[:user_id => user.id, :regroupement_id => groupe.id].destroy
        end 
      rescue => e 
        puts e.message
        error!("mouvaise requete", 400)
      end    
    end
    ##############################################################################

    ##############################################################################

    # i dont know if i need this 
    desc "Rattacher un role a un utilisateur dans un groupe d'eleve"
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

    ##############################################################################

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
    
    ##############################################################################

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

    

    ##############################################################################
    #             Gestion des Groupes libres                                    #
    ##############################################################################
    # pour l'instant les apis concernant les groupes libres son attachés à un etablissement 
    # peut-etre on va les separer àpres.
    desc "liste les groupes libres dans un etablissement"
    params do 
      requires :id, type: String
    end 
    get "/:id/groupes_libres" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil? 
      authorize_activites!([ACT_READ, ACT_MANAGE], etab.ressource, SRV_LIBRE)
      etab.groupes_libres
    end

    ##############################################################################
    desc "retournez les details d'un groupe libre"
    params do 
      requires :id, type: String
      requires :groupe_id, type: Integer
    end 
    get "/:id/groupes_libres/:groupe_id" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      groupe = RegroupementLibre[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil?
      # problem authorize activites groupe libre 
      # authorize_activites!([ACT_READ, ACT_MANAGE], groupe.ressource)
      #groupe
      if params[:expand] == "true"
        present groupe, with: API::Entities::DetailedGroupeLibre
      else
        present groupe, with: API::Entities::SimpleGroupeLibre   
      end
      #groupe
    end

    ##############################################################################   
    desc "creation d'un groupe libre"
    params do 
      requires :id, type: String
      requires :libelle, type: String 
      requires :created_by, type: Integer
      # may be add some description to a group 
      optional :description, type: String   
    end
    post "/:id/groupes_libres"  do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      #authorize_activites!([ACT_CREATE, ACT_MANAGE], Laclasse.ressource, SRV_LIBRE)
      parameters = exclude_hash(params, ["id", "route_info", "session"])
      begin
        #groupe = etab.add_groupe_libre(parameters)
        # find groupe 
        groupe = RegroupementLibre[:libelle => params[:libelle]]
        if groupe 
          puts groupe.inspect
          groupe
        else
          groupe = RegroupementLibre.create(:libelle => params[:libelle], :created_at => Time.now, :created_by => params[:created_by])
          #if params[:description]
            #groupe.description = params[:description]
            #groupe.save
          #end 
        end  
        groupe
      rescue => e
        puts e.message
        error!("mouvaise request", 400) 
      end  
    end 

     ##############################################################################

    desc "modification d'un groupe libre"
    params do 
      requires :id , type: Integer
      requires :groupe_id, type: Integer  
    end 
    put "/:id/groupes_libres/:groupe_id" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], etab.ressource, SRV_LIBRE)

      groupe = Regroupement[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil? 
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], groupe.ressource)
      parameters = exclude_hash(params, ["id", "route_info", "session"])
      begin 
        parameters.each do  |k,v| 
          if groupe.respond_to?(k.to_sym)
            groupe.set(k.to_sym => v) 
          end    
        end
        groupe.save 
      rescue => e 
        error!("mouvaise requete", 400)
      end 
    end

     ##############################################################################
    desc "suppression d'un groupe libre"
    params do 
      requires :id , type:String
      requires :groupe_id, type:Integer
    end 
    delete "/:id/groupes_libres/:groupe_id" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_DELETE, ACT_MANAGE], etab.ressource, SRV_LIBRE)

      groupe = RegroupementLibre[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil? 
      authorize_activites!([ACT_DELETE, ACT_MANAGE], groupe.ressource)
      begin
        groupe.destroy
      rescue  => e
        error!("mouvaise requete", 400)  
      end 
    end
     ##############################################################################

    desc "Ajouter un membre au regroupement Libre"
    params do
      requires :id, type: String 
      requires :groupe_id , type: Integer
      requires :user_id, type: String
    end
    post "/:id/groupes_libres/:groupe_id/membres" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      groupe = RegroupementLibre[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil?

      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      
      begin 
        membre = MembreRegroupementLibre[:user_id => user.id, :regroupement_libre_id => groupe.id]
        if membre 
          membre
        else 
          MembreRegroupementLibre.create(:user_id => user.id, :regroupement_libre_id => groupe.id, :joined_at => DateTime.now)
        end   
      rescue => e 
        puts e.message
        error!("mouvaise requete", 400)
      end    
    end 

     ##############################################################################
    desc "supprimer un membre du groupe"
    params do
      requires :id, type: String 
      requires :groupe_id , type: Integer
      requires :membre_id, type: String
    end
    delete "/:id/groupes_libres/:groupe_id/membres/:membre_id" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      
      groupe = RegroupementLibre[:id => params[:groupe_id]]
      error!("ressource non trouvee", 404) if groupe.nil?


      user = User[:id_ent => params[:membre_id]]
      error!("ressource non trouvee", 404) if user.nil?

      begin
        membre = MembreRegroupementLibre[:user_id => user.id, :regroupement_libre_id => groupe.id]
        if membre 
          membre.destroy
        end 
      rescue =>  e
        error!("mouvaise requete", 400)
      end 
    end

    ##############################################################################
    desc "gestion des role dans un groupe d'eleves"
    params do 
      requires :id, type: Integer
      requires :groupe_id, type: Integer
      
    end
    post "/:id/groupe_eleve/:groupe_id/role_user/:user_id" do
      # role ou profil  
    end
    ##############################################################################


    ##############################################################################
    # []
    desc "Recuperer les niveaux des classes" 
    params do 
      requires :id, type: String
    end 
    get "/:id/niveaux" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
        #Regroupement.filter(:etablissement_id => etab.id).select(:niveau_id)
        Niveau.select(:ent_mef_jointure,:mef_libelle).naked.all
    end 

    ##############################################################################
    #                     Gestion des profils                                    #
    ##############################################################################

    #{profil_id: "ELV"}
    desc "Ajout d'un profils utilisateur"
    params do 
      requires :id, type: String
      requires :user_id , type: String
      requires :profil_id, type: String
    end  
    post "/:id/profil_user/:user_id" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("etablissement non trouve", 404) if etab.nil?

      user = User[:id_ent => params[:user_id]]
      error!("user non trouvee", 404) if user.nil?

      profil = Profil[:id => params[:profil_id]]
      error!("profil non trouvee", 404) if profil.nil?
      begin
        authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)
        user.add_profil(etab.id, profil.id)
        ProfilUser[:user_id => user.id, :etablissement_id => etab.id, :profil_id => profil.id] 
      rescue  => e 
        error!(e.message, 400)
      end 
    end   
    
     ##############################################################################
    #{new_profil_id: "PROF", etablissement_id: 1234}
    desc "Modification d'un profil"
    params do  
      requires :id, type: String
      requires :user_id, type: String
      requires :old_profil_id, type: String
      requires :new_profil_id, type: String
    end 
    put "/:id/profil_user/:user_id/:old_profil_id" do 
      etab = Etablissement[:code_uai => params[:id]]
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
        error!(e.message, 400)
      end 
    end 
    

     ##############################################################################
    desc "Suppression d'un profil"
    params do 
      requires :id, type: String
      requires :user_id, type: String 
      requires :profil_id , type: String 
    end 
    delete "/:id/profil_user/:user_id/:profil_id" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      profil = Profil[:id => params[:profil_id]]
      error!("ressource non trouvee", 404) if profil.nil?
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)
      begin
        # delete corresponding role

        RoleUser[:user_id => user.id, :role_id => profil.role_id].destroy
        # delete user's profile 
        ProfilUser[:profil_id => profil.id, :user_id => user.id, :etablissement_id => etab.id].destroy  
      rescue => e 
        error!(e.message, 400)
      end
    end


    ##############################################################################
    #                       Etablissement User Telephone Api                     #
    ##############################################################################

    #recuperer la liste des telephones qui appartien à un utilisateur 
    desc "recuperer les telephones"
    get "/:id/users/:user_id/telephones" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      authorize_activites!([ACT_READ, ACT_MANAGE], user.ressource)
      user.telephone.map{|tel| {id: tel.id, numero: tel.numero, type: tel.type_telephone_id} } 
    end 
    
    ##############################################################################
    #ajouter un telephone
    desc "ajouter un numero de telephone à l'utilisateur"
    params do
      requires :numero, type: String
      optional :type_telephone_id, type: String
    end
    post "/:id/users/:user_id/telephone"do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
     
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)
      numero = params["numero"]
      if !params["type_telephone_id"].nil? and ["MAIS", "PORT", "TRAV", "AUTR"].include?(params["type_telephone_id"])
        type_telephone_id = params["type_telephone_id"]
        user.add_telephone(numero, type_telephone_id)
      else
        user.add_telephone(numero)
      end
    end

    ##############################################################################
    #modifier le telephone
    desc "modifier un telephone" 
    params do
      requires :telephone_id, type: Integer
      optional :numero, type: String
      optional :type_telephone_id, type: String
    end
    put "/:id/users/:user_id/telephone/:telephone_id"  do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
     
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)

      tel = user.telephone_dataset[params[:telephone_id]]  
      error!("ressource non trouvée", 404) if tel.nil?
      
      tel.set(:numero => params[:numero]) if params[:numero]
      tel.set(:type_telephone_id  => params[:type_telephone_id]) if params[:type_telephone_id]

      begin
        tel.save()
      rescue => e
        error!("Erreur lors de la sauvegarde : #{e.message}", 400)
      end
    end
     ##############################################################################
    #supprimer un telephone 
    desc "suppression d'un telephone"
    delete "/:id/users/:user_id/telephone/:telephone_id"  do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
     
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)

      if params["telephone_id"].nil? or params["telephone_id"].empty? 
        error!("mouvaise requete", 400)
      elsif !user.telephone.map{|tel| tel.id}.include?(params["telephone_id"].to_i)  
        error!("ressource non trouvé", 404)
      else
        tel = Telephone[:id => params["telephone_id"].to_i]
        tel.destroy
      end
    end
    #############################################################################
    #                           Gestion des emails                              #
    #############################################################################
    desc "recuperer la liste des emails de l'etablissement"

    get "/:id/users/:user_id/emails" do 
      
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
     
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      
      authorize_activites!([ACT_READ, ACT_MANAGE], user.ressource)

      emails = user.email
      emails.map  do |email|
        {:id => email.id, :adresse => email.adresse, :academique => email.academique, :principal => email.principal}
      end
    end

    ##############################################################################
    desc "ajouter un email à l'utilisateur"
    params do
      requires :adresse, type: String
      optional :academique, type: Boolean
    end
    post "/:id/users/:user_id/emails" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
     
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)

      academique = params[:academique] ? true : false 
      user.add_email(params[:adresse], academique)

      present user, with: API::Entities::SimpleUser
    end

    ##############################################################################
    # modifier l'adresse et le type de l'email
    # l'email doit apartenir à l'utilisateur user_id
    desc "modifier un email existant"
    params do
      requires :email_id, type: Integer
      optional :adresse, type: String
      optional :academique, type: Boolean
      optional :principal, type: Boolean
    end
    put "/:id/users/:user_id/emails/:email_id" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
     
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      
      email = Email[:id => params[:email_id]] 
      check_email!(user, email)
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)

      email.adresse = params[:adresse] if params[:adresse]
      email.academique = params[:academique] if params[:academique]
      email.principal = params[:principal] if params[:principal]
      #Todo : si l'utilisateur à déjà un email principal, faut-il l'enlever ou générer une erreur ?
      email.save()

      present user, with: API::Entities::SimpleUser
    end

    ##############################################################################
    # supprimer un des email de l'utilisateur 
    desc "supprimer un email"
    params do
      requires :email_id, type: Integer
    end
    delete ":id/users/:user_id/emails/:email_id" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
     
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?

      email = Email[:id => params[:email_id]] 
      check_email!(user, email)

      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)

      email.destroy()

      present user, with: API::Entities::SimpleUser
    end

    ##############################################################################
    #                  Gestion des parametres                                    #
    ##############################################################################

    desc "Recupere tous les parametres sur une application donnee"
    params do
      requires :id, type: String
      requires :app_id, type: String  
    end 
    get "/:id/applications/:app_id/parametres" do
      etab = Etablissement[:code_uai => params[:id]]
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

    ##############################################################################
    #note: is it necessary to do the casting
    desc "Recupere la valeur d'un parametre precis"
    params do 
      requires :id, type: Integer 
      requires :app_id, type: String
      requires :code , type: String 
    end 
    get "/:id/parametres/:app_id/:code" do
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
        error!("mouvaise requete", 400)
      end 
    end 
    
     ##############################################################################
    desc "Modifie la valeur d'un parametre"
    params do 
      requires :id, type: String 
      requires :app_id, type: String
      requires :param_id , type: Integer
      requires :value 
    end 
    put "/:id/applications/:app_id/parametres/:param_id" do
      #puts params.inspect
      #note detect if value is acceptable or not 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      app = Application[:id => params[:app_id]]
      error!("ressource non trouvee", 404) if app.nil?

      param_application = ParamApplication[:id => params[:param_id]]
      error!("ressource non trouvee", 404) if param_application.nil?
 
      begin
        id = param_application.id
        value = params[:value]
        etab.set_preference(id, value)
      rescue => e
        error!("mouvaise requete", 400)
      end 

    end

     ##############################################################################
    desc "Remettre la valeure par defaut du parametre"
    params do 
      requires :id, type: String
      requires :app_id, type: String 
      requires :code , type: String
    end   
    delete "/:id/applications/:app_id/parametres/:code" do 
      etab = Etablissement[:code_uai => params[:id]]
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

    ##############################################################################
    
    desc "Recupere tous les  parametres de l'etablissement pour tous les applications" 
    params do 
      requires :id, type: String
    end 
    get "/:id/parametres" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      # add authorization
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


    ##############################################################################
    #           Gestion des applications et Activation                           #
    ##############################################################################

    ##############################################################################
    # example : {"DOC", "CAHIER_TXT"}
    desc "Gestion de l'activation des applications"
    params do 
      requires :id, type: Integer 
    end 
    get ":id/application_actifs" do
      etab = Etablissement[:id => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      begin
        DB[:application_etablissement].filter(:etablissement_id => etab.id).select(:application_id).all
      rescue => e 
        error!("mouvaise requete", 400)
      end 
    end
    
    ##############################################################################
    desc "Return the list of applications in the (etablissement)"
    params do 
      requires :id, type:String
    end
    get ":id/applications" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?
      ApplicationEtablissement.filter(:etablissement_id => etab.id)
      .join(:application, :application__id => :application_id)
      .select(:application_id, :etablissement_id,:application_etablissement__active, :id, :libelle, :description, :url)
      .naked.all
    end  
    ##############################################################################
    #{actif: true|false}
    desc "Activer ou desactiver une application"
    params do 
      requires :id , type: String
      requires :app_id , type: String
      requires :actif , type: Boolean 
    end 
    put ":id/applications/:app_id" do
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 404) if etab.nil?

      app = Application[:id => params[:app_id]]
      error!("ressource non trouvee", 400) if app.nil?
      activate = params[:actif]

      application = ApplicationEtablissement[:etablissement_id => etab.id, :application_id => app.id] 
      begin 
        if activate 
          if application
            application.active = true 
            application.save 
          else
            ApplicationEtablissement.create(:etablissement_id => etab.id, :application_id => app.id)
          end      
        else
          if application
            application.active = false
            application.save
          end   
        end 
      rescue => e 
        #puts e.message 
        error!("mouvaise requete", 400)
      end  
    end
    
    ##############################################################################
    desc "Ajouter une application à l'etablissement"
    params do
      requires :id, type:String
      requires :app_id,  type:String
    end
    post ":id/applications/:app_id" do 
      puts params.inspect 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 400) if etab.nil?
      application = ApplicationEtablissement[:etablissement_id => etab.id, :application_id => params[:app_id]]
      if application 
        application 
      else
        application = ApplicationEtablissement.create(:etablissement_id => etab.id, :application_id => params[:app_id])
      end 
    end 
    ##############################################################################
    desc "supprimer l'application de l'etablissement"
    params do 
      requires :id, type:String 
      requires :app_id, type:String 
    end

    delete ":id/applications/:app_id" do 
      etab = Etablissement[:code_uai => params[:id]]
      error!("ressource non trouvee", 400) if etab.nil?
      ApplicationEtablissement.filter(:etablissement_id => etab.id, :application_id => params[:app_id]).destroy()
    end 
    ##############################################################################
    desc "Return the list of (etablissements) types"
    params do 
    end 
    get "/types/types_etablissements" do 
      TypeEtablissement.naked.all
    end   

  end

end

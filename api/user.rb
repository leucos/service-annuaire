#coding: utf-8
class UserApi < Grape::API
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
    def check_user!(message = "Utilisateur non trouvé", param_id = :user_id)
      authenticate!
      user = User[:id_ent => params[param_id]]
      error!(message, 404) if user.nil?
      #puts user.inspect
      return user
    end

    def check_email!(user)
      email = Email[:id => params[:email_id]]
      error!("Email non trouvé", 404) if email.nil? or !user.has_email(email.adresse)
      return email
    end

    def modify_user(user)
      # Use the declared helper
      declared(params, include_missing: false).each do |k,v|
        if user.respond_to?(k.to_sym)
          user.set(k.to_sym => v)
        end  
      end
      user.save()
    end
  end

  resource :users do
    ##############################################################################
    desc "Renvois le profil utilisateur si on donne le bon id. Nécessite une authentification."
    get "/:user_id", :requirements => { :user_id => /.{8}/ } do
      user = check_user!() 
      authorize_activites!([ACT_READ, ACT_MANAGE], user.ressource)
      if params[:expand] == "true"
        present user, with: API::Entities::DetailedUser
      else 
        present user, with: API::Entities::SimpleUser
      end 
    end

    ##############################################################################
    # Renvois la ressource user
    desc "Service de création d'un utilisateur"
    params do
      # todo : optional mais si password, login obligé et vice/versa ?
      requires :login, type: String, desc: "Doit commencer par une lettre et ne pas comporter d'espace"
      requires :password, type: String
      requires :nom, type: String
      requires :prenom, type: String
      optional :sexe, type: String, desc: "Valeurs possibles : F ou M"
      optional :date_naissance, type: Date
      optional :adresse, type: String
      optional :code_postal, type: Integer, desc: "Ne doit comporter que 6 chiffres" 
      optional :ville, type: String
      optional :id_sconet, type: Integer
      optional :id_jointure_aaf, type: Integer
      optional :profil, type: String
      optional :etablissement, type: String
    end
    post do
      authorize_activites!([ACT_CREATE, ACT_MANAGE], Ressource.laclasse, SRV_USER)
      user = User.new
      modify_user(user)
      if !params[:profil].nil? && !params[:etablissement].nil?
        etab = Etablissement[:code_uai => params[:etablissement]]
        profil = Profil[:id => params[:profil]]
        if !profil.nil? && !etab.nil?
          user.add_profil(etab.id,profil.id)
        end 
      end
      present user, with: API::Entities::SimpleUser
    end


    ##############################################################################
    # Même chose que post mais peut ne pas prendre des champs require
    # Renvois la ressource user complète
    desc "Modification d'un compte utilisateur"
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
    put "/:user_id" do
      user = check_user!()
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)
      modify_user(user)
      present user, with: API::Entities::SimpleUser
    end

    ##############################################################################
    # Supprime un utilisateur 
    desc "Supprission d'un compte utilisateur"
    params do
      requires :user_id, type:String
    end
    delete "/:user_id" do
      user = check_user!()
      if user
        authorize_activites!([ACT_DELETE, ACT_MANAGE], user.ressource)
        user.destroy()
        puts "user deleted"
      end
    end

    # Récupération des relations 
    # returns the relations of a user 
    # actually not complet 
    get "/:user_id/relations" do 
      user = check_user!()
      
      authorize_activites!([ACT_READ, ACT_MANAGE], user.ressource)
      user.relations
    end

    ##############################################################################
    #Il ne peut y en avoir qu'une part adulte
    #Cas d'un user qui devient parent d'élève {eleve_id: VAA60001, type_relation_id: "PAR"}
    desc "Ajout d'une relation entre un adulte et un élève"
    params do
      requires :eleve_id, type: String
      requires :type_relation_id, type: String
    end 
    post "/:user_id/relation" do
      user = check_user!("Adulte non trouvé")
      eleve = check_user!("Eleve non trouvé", :eleve_id)

      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)

      type_rel = TypeRelationEleve[params[:type_relation_id]]
      error!("Type de relation invalide", 400) if type_rel.nil? 
      relation = user.find_relation(eleve)
      error!("Relation déjà existante", 400) if relation

      user.add_enfant(eleve, type_rel.id)

      present user, with: API::Entities::SimpleUser
    end

    ##############################################################################
    desc "Modification de la relation"
    params do
      requires :type_relation_id, type: String
      requires :eleve_id, type: String
    end
    put "/:user_id/relation/:eleve_id" do
      user = check_user!("Adulte non trouvé")
      eleve = check_user!("Eleve non trouvé", :eleve_id)

      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)

      type_rel = TypeRelationEleve[params[:type_relation_id]]
      relation = user.find_relation(eleve)
      error!("Type de relation invalide", 400) if type_rel.nil?
      error!("Relation inexistante", 404) if relation.nil?

      relation.update(:type_relation_eleve_id => type_rel.id)

      present user, with: API::Entities::SimpleUser
    end
    

    ##############################################################################
    # @state[not finished]
    #Suppression de la relation (1 par adulte)
    #DEL /user/:user_id/relation/:eleve_id 
    desc "suppression d'une relation adulte/eleve"
    params do
      requires :eleve_id, type: String
    end
    delete "/:user_id/relation/:eleve_id" do 
      user = check_user!("Adulte non trouvé")
      eleve = check_user!("Eleve non trouvé", :eleve_id)

      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)

      relation = user.find_relation(eleve)
      error!("Relation inexistante", 404) if relation.nil?

      relation.destroy()

      present user, with: API::Entities::SimpleUser
    end

    ##############################################################################
    desc "recuperer la liste des emails"
    get "/:user_id/emails" do 
      user = check_user!()

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
    post ":user_id/email" do
      user = check_user!()

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
    put ":user_id/email/:email_id" do
      user = check_user!()
      email = check_email!(user)
      
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
    delete ":user_id/email/:email_id" do
      user = check_user!()
      email = check_email!(user)

      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)

      email.destroy()

      present user, with: API::Entities::SimpleUser
    end

    ##############################################################################
    desc "Envois un email de verification à l'utilisateur sur l'email choisit"
    params do
      requires :user_id, type: String
      requires :email_id, type: Integer
    end
    get ":user_id/email/:email_id/validate" do
      user = check_user!()
      email = check_email!(user)

      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)

      email.send_validation_mail()
    end

    ##############################################################################
    desc "Envois un email de verification à l'utilisateur sur l'email choisit"
    params do
      requires :user_id, type: String
      requires :email_id, type: Integer
    end
    get ":user_id/email/:email_id/validate/:validation_key" do
      user = check_user!()
      email = check_email!(user)

      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)

      valide = email.check_validation_key(params[:validation_key])
      error!("Clé de validation invalide ou périmée", 404) unless valide
    end

    ##############################################################################
    #                       User Telephone Api                                   #
    ##############################################################################

    #recuperer la liste des telephones qui appartien à un utilisateur 
    desc "recuperer les telephones"
    get ":user_id/telephones" do
      user = check_user!()
      
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
    post ":user_id/telephone"do
      user = check_user!()

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
    put ":user_id/telephone/:telephone_id"  do 
      user = check_user!()

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
    delete ":user_id/telephone/:telephone_id"  do
      user = check_user!()

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
    desc "Retourner la liste des applications d'un utilisateur"
    get ":user_id/applications" do
      user = check_user!()
      authorize_activites!([ACT_READ, ACT_MANAGE], user.ressource)
      user.applications
    end

    ##############################################################################
    #Récupère les préférences d'une application
    desc "Récupère les préférences d'une application d'un utilisateur"
    get ":user_id/applications/:application_id/preferences" do
      user = check_user!()
      
      authorize_activites!([ACT_READ, ACT_MANAGE], user.ressource)

      application_id = params["application_id"]
      application = Application[:id => application_id]
      user.preferences(application_id)
    end

    ##############################################################################
    #Modifie une préférence
    desc "Modifier une(des) preferecne(s)"
    put ":user_id/applications/:application_id/preferences" do
      user = check_user!()

      authorize_activites!([ACT_UPDATE,ACT_MANAGE], user.ressource)

      application_id = params["application_id"]
      application = Application[:id => application_id]
      
      preferences  = params.select {|key, value|  (key != "route_info" and key != "user_id" and key != "application_id")  }
      #puts preferences.inspect
      # no preferences are sent
      if preferences.count == 0 
        error!("mauvaise requete", 403)
      end
      i = 0
      preferences.each do |code, value|
        param_application = ParamApplication[:code => code]
        if param_application.nil?
          i+=1
        end
      end
      # all preferences are not valid
      if preferences.count == i and i > 0
        error!("mauvaise requete", 403)
      end
      preferences.each do |code, value|
        param_application = ParamApplication[:code => code]
        if !param_application.nil? and param_application.application_id == application_id
          user.set_preference(param_application.id, value)
        end
      end
    end

    ##############################################################################
    #Remettre la valeure par défaut pour toutes les préférences
    desc "Remettre la valeure par défaut pour toutes les préférences"
    delete ":user_id/application/:application_id/preferences" do 
      user = check_user!()

      authorize_activites!([ACT_UPDATE, ACT_MANAGE], user.ressource)

      application_id = params["application_id"]
      application = Application[:id => application_id]

      preferences = ParamUser.filter(:user  => user).select(:param_application_id).all
      preferences.each do |paramuser|
        param_application = ParamApplication[:id => paramuser.param_application_id]
        if !param_application.nil? and param_application.application_id == application_id
          user.set_preference(param_application.id, nil)
        end
      end
    end

    ##############################################################################
    # todo : gérer aussi les récupération de mot de passe avec login 
    # et envoie de mail au parent si l'élève n'a pas d'email ?
    # todo : comment limiter les appel à cette api pour éviter le spamming ?
    # Api publique
    desc "Procedure de regénération des mots de passe. Envois un mail à la personne à qui le login ou l'adresse mail appartient"
    params do
      requires :adresse, type: String
      optional :login, type: String
    end
    get "forgot_password" do
      # Si l'adresse passée en paramètre correspond à plusieurs login et qu'on a pas le login passé en paramètre
      # On renvois une erreur
      if params[:login]
        user = User[:login => params[:login]]
        error!("Utilisateur non trouvé", 404) if user.nil?
      else
        dataset = User.filter(:email => Email.filter(:adresse => params[:adresse]))
        nb_adresses = dataset.count
        error!("Cette adresse est liée à plusieurs utilisateurs", 404) if nb_adresses > 1
        error!("Aucun utilisateur ne correspond à cette adresse", 404) if nb_adresses == 0

        user = dataset.first
      end

      # send_password_mail va générer une erreur si l'email n'appartient pas à l'utilisateur ou à ses parents
      user.send_password_mail(params[:adresse])
    end

    ##############################################################################
    # réintialization du mot de pass 
    desc "reinitializer le mot de pass par defaut d'un utilisateur"
    post ":user_id/password/initialize" do
      # authenticated_user
      user = check_user!()
      error!("Utilisateur non trouvé", 404) if user.nil?
      # current user is authorized to modify user password
      authorize_activites!([ACT_MANAGE, ACT_UPDATE], user.ressource)
      user.initialize_password
      user
    end
    
    ##############################################################################
    desc "Simple service permettant de savoir si un login est disponible et valide"
    params do
      requires :login, type: String
    end
    get "login_available" do
      login = params[:login]
      result = {}
      if User.is_login_valid?(login)
        if User.is_login_available?(login)
          result[:message] = "Login disponible"
        else
          result[:error] = "Login non disponible"
        end
      else
        result[:error] = "Login invalide"
      end
      result
    end

    ##############################################################################
    desc "Service de recherche d'utilisateurs au niveau de LACLASSE"
    params do
      optional :query, type: String, desc: "pattern de recherche. Possibilité de spécifier la colonne sur laquelle faire la recherche ex: 'nom:Chackpack prenom:Georges'"
      optional :limit, type: Integer, desc: "Nombre maximum de résultat renvoyés"
      optional :page, type: Integer, desc: "Dans le cas d'une requète paginée"
      optional :sort_col, type: String, desc: "Nom de la colonne sur laquelle faire le tri"
      optional :sort_dir, type: String, regexp: /^(asc|desc)$/i, desc: "Direction de tri : ASC ou DESC"
      group :advanced do
        optional :prenom, type: String
        optional :nom, type: String
        optional :login, type: String
        optional :etablissement, type: String, desc: "Nom de l'établissement dans lequel est l'utilisateur"
        optional :user_id, type: String
      end
    end
    get do
      authorize_activites!([ACT_READ, ACT_MANAGE], Ressource.laclasse, SRV_USER)
      # todo : manque user_id et etablissement
      accepted_fields = {
        prenom: :prenom, nom: :user__nom, login: :login, code_uai: :etablissement__code_uai, etablissement: :etablissement__nom, id_ent: :id_ent, profil_id: :profil_user__profil_id, profil: :profil_national__description
      }

      dataset = User.search_all_dataset()

      results = super_search!(dataset, accepted_fields)

      # Code à décommenter si search_all_dataset n'utilise plus select_json_array!
      # results[:results].each do |u|
      #   user = User[u[:id]]
      #   u[:emails] = user.email_dataset.naked.all
      #   u[:telephones] = user.telephone_dataset.naked.all
      #   u[:profils] = user.profil_user_display.naked.all
      # end

      # puts results.inspect
      results
    end

    ##############################################################################
    #                         Gestion des roles                                  # 
    ##############################################################################
    
    desc "Assigner un role à un utilisateur"
    params do
      requires :user_id, type: String 
      requires :role_id, type: String
      requires :etab_id, type: String
    end  
    post "/:user_id/roles/:role_id/:etab_id" do 
      # check if user is authorized to  change the role of an other user
      #authorize_activites!(ACT_CREATE, etab.ressource)
      authorize_activites!([ACT_UPDATE, ACT_MANAGE], Ressource.laclasse, SRV_USER)
      authorize_activites!([ACT_CREATE, ACT_MANAGE], Ressource.laclasse, SRV_ROLE)

      etab = Etablissement[:code_uai => params.etab_id]
      error!("ressource non trouvee", 404) if etab.nil?
      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      role = Role[:id => params[:role_id]]

      error!("ressource non trouvee", 404) if role.nil?
      begin 
        #ressource = etab.ressource
        user.add_role(etab.id, role.id)  
      rescue => e
        #puts e.message
        error!("Validation Failed", 400)
      end
      {:user_id => user.id, :user_role => role.id, :etablissement => etab.nom}     
    end

   ############################################################
    desc "Modifier le role de quelqu'un"
    params do 
      requires :user_id, type: String
      requires :old_role_id, type: String
      requires :new_role_id, type: String
      requires :etab_id, type: String
      requires :new_etab_id, type: String     
    end  
    put "/:user_id/roles/:old_role_id/:etab_id" do
      etab = Etablissement[:code_uai => params.etab_id]
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_UPDATE, ACT_MANAGE],Ressource.laclasse, SRV_USER)
      authorize_activites!([ACT_CREATE, ACT_MANAGE], Ressource.laclasse, SRV_ROLE)

      user = User[:id_ent => params[:user_id]]
      error!("ressource non trouvee", 404) if user.nil?
      old_role = Role[:id => params[:old_role_id]]
      error!("ressource non trouvee", 404) if old_role.nil?
      new_role = Role[:id => params[:new_role_id]]
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
    ############################################################
    desc "Supprimer le role de l'utilisateur"
    params do 
      requires :etab_id, type: String
      requires :user_id, type: String
      requires :role_id, type: String
    end 
    delete "/:user_id/roles/:role_id/:etab_id" do
      etab = Etablissement[:code_uai => params[:etab_id]]                                                                                                                                                                                                                         
      error!("ressource non trouvee", 404) if etab.nil?
      authorize_activites!([ACT_UPDATE, ACT_MANAGE],Ressource.laclasse, SRV_USER)
      authorize_activites!([ACT_DELETE, ACT_MANAGE], Ressource.laclasse, SRV_ROLE)
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
     ############################################################

  end #resource
end
#coding: utf-8

class UserApi < Grape::API
  format :json
  error_format :json

  helpers RightHelpers
  helpers do
    # return an array of columns 
    def model
      params['model'].capitalize
    end
    # input user_name 
    # output UserName
    def classify(string)
      string.split('_').collect!{ |w| w.capitalize }.join
    end
    #change hash keys to symbols
    def symblize_hash(h)
      h.keys.each do |key|
        h[(key.to_sym rescue key) || key] = h.delete(key)
      end 
    end
    def symbolize_array(arr)
      arr.map{|v| v.is_a?(String) ? v.to_sym : v}
    end

    def check_user!(message = "Utilisateur non trouvé", param_id = :user_id)
      user = User[params[param_id]]
      error!(message, 404) if user.nil?
      return user
    end

    def modify_user(user)
      params.each do |k,v|
        # todo : Un peu hacky mais je ne vois pas comment faire autrement...
        if k != "user_id" and k != "route_info" and k != "session_key"
          begin
            if user.respond_to?(k.to_sym) 
              user.set(k.to_sym => v)
            else
              error!("Parametre #{k} non pris en charge", 400)
            end
          rescue Sequel::ValidationFailed
            error!("Validation failed", 400)
          end
        end
      end

      begin
        user.save()
      rescue Sequel::ValidationFailed
        error!("Validation failed", 400)
      end
    end
  end

  desc "Renvois le profil utilisateur si on donne le bon id. Nécessite une authentification."
  get "/:user_id" do
    user = check_user!()
    authorize_activites!(ACT_READ, user.ressource)
    present user, with: API::Entities::User
  end

  # Renvois la ressource user
  desc "Service de création d'un utilisateur"
  params do
    # todo : optional mais si password, login obligé et vice/versa
    requires :login, type: String, desc: "Doit commencer par une lettre et ne pas comporter d'espace"
    optional :password, type: String
    requires :nom, type: String
    requires :prenom, type: String
    optional :sexe, type: String, desc: "Valeurs possibles : F ou M"
    optional :date_naissance, type: Date
    optional :adresse, type: String
    optional :code_postal, type: Integer, desc: "Ne doit comporter que 6 chiffres" 
    optional :ville, type: String
    optional :id_sconet, type: Integer
    optional :id_jointure_aaf, type: Integer
  end
  post do
    authorize_activites!(ACT_CREATE, Ressource.laclasse, SRV_USER)
    user = User.new()

    modify_user(user)
    
    present user, with: API::Entities::User
  end

  # Même chose que post mais peut ne pas prendre des champs require
  # Renvois la ressource user complète
  desc "Modification d'un compte utilisateur"
  put "/:user_id" do
    user = check_user!()
    authorize_activites!(ACT_UPDATE, user.ressource)

    modify_user(user)

    present user, with: API::Entities::User
  end

  desc "a service to search users according to certiain informations"
  # look at tests to see some examples about parameters
  get "/query/users"  do
    authorize_activites!(ACT_READ, Ressource.laclasse, SRV_USER)
    params["columns"].nil? ? columns = User.columns : columns = symbolize_array(params["columns"].split(","))
    #filter_params
    filter = params["where"].nil? ? {} : params["where"].to_hash
    symblize_hash(filter)

    filter.keys.each do |k|
      # key is of a pattern ex. user_profil.etablissement_id  where user_profil is an association and etablissment_id is a column in the association table
      if(k =~ /\w*[.][a-z]+/) 
          association_array= k.to_s.split(".")
          association = symbolize_array(association_array) 
          model_name  = classify(association[0].to_s)
          begin 
            raise "error"  if !User.associations.include?(association[0])
            model = Kernel.const_get(model_name)
            column = association[1]
            raise "error"  if !model.columns.include?(column)
             # add if filter[assocition] exists add filter to the request
            if filter[association[0]].nil?
                filter[association[0]] =  model.filter(column => filter[k])
            else 
              filter[association[0]] = filter[association[0]].filter(column => filter[k])
            end 
          rescue
             error!("Bad Request : invalid parameters", 400)  
          end   
          #puts model_column.inspect
          filter.delete(k)
      elsif( !User.columns.include?(k))
        error!("Bad Request", 400)  unless User.columns.include?(k)
      end
    end
    start = params["start"].nil? || params["start"].empty? ? 0 : params["start"]
    length = params["length"].nil? || params["length"].empty? ? 10 : params["length"]
    sortdir = params["sortdir"].nil? ? "" : params["sortdir"]
    sortcol = params["sortcol"].nil? || params["sortcol"].empty? ? 1 : columns.include?(params["sortcol"].to_sym) ? columns.index(params["sortcol"].to_sym) : 1 
    search = params["search"].nil? ?  '' : params["search"]

    response = PagedQuery.new('User', columns, filter, start, length, sortcol, sortdir, search)
    response.as_json
  end

  # Récupération des relations 
  # returns the relations of a user 
  # actually not complet 
  get "/:user_id/relations" do 
    user = check_user!()
    
    authorize_activites!(ACT_READ, user.ressource)
    user.relations
  end

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
    type_rel = TypeRelationEleve[params[:type_relation_id]]
    error!("Type de relation invalide", 400) if type_rel.nil? 
    relation = user.find_relation(eleve)
    error!("Relation déjà existante", 400) if relation

    user.add_enfant(eleve, type_rel.id)

    present user, with: API::Entities::User
  end

  desc "Modification de la relation"
  params do
    requires :type_relation_id, type: String
    requires :eleve_id, type: String
  end
  put "/:user_id/relation/:eleve_id" do
    user = check_user!("Adulte non trouvé")
    eleve = check_user!("Eleve non trouvé", :eleve_id)
    type_rel = TypeRelationEleve[params[:type_relation_id]]
    relation = user.find_relation(eleve)
    error!("Type de relation invalide", 400) if type_rel.nil?
    error!("Relation inexistante", 404) if relation.nil?

    relation.update(:type_relation_eleve_id => type_rel.id)

    present user, with: API::Entities::User
  end
  

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
    relation = user.find_relation(eleve)
    error!("Relation inexistante", 404) if relation.nil?

    relation.destroy()

    present user, with: API::Entities::User
  end

  desc "recuperer la liste des emails"
  get "/:user_id/emails" do 
    u = check_user!()

    emails = u.email
    emails.map  do |email|
      {:id => email.id, :adresse => email.adresse, :academique => email.academique, :principal => email.principal}
    end
  end

  desc "ajouter un email à l'utilisateur"
  params do
    requires :adresse, type: String
    optional :academique, type: Boolean
  end
  post ":user_id/email" do
    user = check_user!()
    academique = params[:academique] ? true : false 
    user.add_email(params[:adresse], academique)

    present user, with: API::Entities::User
  end

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
    email = Email[:id => params[:email_id]]
    error!("Email non trouvé", 404) if email.nil? or !user.has_email(email)
    
    email.adresse = params[:adresse] if params[:adresse]
    email.academique = params[:academique] if params[:academique]
    email.principal = params[:principal] if params[:principal]
    #Todo : si l'utilisateur à déjà un email principal, faut-il l'enlever ou générer une erreur ?
    email.save()

    present user, with: API::Entities::User
  end

  # supprimer un des email de l'utilisateur 
  desc "supprimer un email"
  params do
    requires :email_id, type: Integer
  end
  delete ":user_id/email/:email_id" do
    user = check_user!()
    email = Email[:id => params[:email_id]]
    error!("Email non trouvé", 404) if email.nil? or !user.has_email(email)
    email.destroy()

    present user, with: API::Entities::User
  end

  desc "Envois un email de verification à l'utilisateur sur l'email choisit"
  params do
    requires :user_id, type: String
    requires :email_id, type: Integer
  end
  get ":user_id/email/:email_id/validate" do
    user = check_user!()
    email = Email[:id => params[:email_id]]
    error!("Email non trouvé", 404) if email.nil? or !user.has_email(email)

    email.send_validation_mail()
  end

  desc "Envois un email de verification à l'utilisateur sur l'email choisit"
  params do
    requires :user_id, type: String
    requires :email_id, type: Integer
  end
  get ":user_id/email/:email_id/validate/:validation_key" do
    user = check_user!()
    email = Email[:id => params[:email_id]]
    error!("Email non trouvé", 404) if email.nil? or !user.has_email(email)

    valide = email.check_validation_key(params[:validation_key])
    error!("Clé de validation invalide ou périmée", 404) unless valide
  end

  #recuperer la liste des telephones qui appartien à un utilisateur 
  desc "recuperer les telephones"
  get ":user_id/telephones" do
    user = check_user!()
    user.telephone.map{|tel| {id: tel.id, numero: tel.numero, type: tel.type_telephone_id} } 
  end 
  
  #ajouter un telephone
  desc "ajouter un numero de telephone à l'utilisateur"
  params do
    requires :numero, type: String
    optional :type_telephone_id, type: String
  end
  post ":user_id/telephone"do
    user = check_user!()
    numero = params["numero"]
    if !params["type_telephone_id"].nil? and ["MAIS", "PORT", "TRAV", "AUTR"].include?(params["type_telephone_id"])
      type_telephone_id = params["type_telephone_id"]
      user.add_telephone(numero, type_telephone_id )
    else
      user.add_telephone(numero)
    end
  end

  #modifier le telephone
  desc "modifier un telephone" 
  params do
    requires :telephone_id, type: Integer
    optional :numero, type: String
    optional :type_telephone_id, type: String
  end
  put ":user_id/telephone/:telephone_id"  do 
    user = check_user!()
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

  #supprimer un telephone 
  desc "suppression d'un telephone"
  delete ":user_id/telephone/:telephone_id"  do
    user = check_user!()
    if params["telephone_id"].nil? or params["telephone_id"].empty? 
      error!("mouvaise requete", 400)
    elsif !user.telephone.map{|tel| tel.id}.include?(params["telephone_id"].to_i)  
      error!("ressource non trouvé", 404)
    else
      tel = Telephone[:id => params["telephone_id"].to_i]
      tel.destroy
    end
  end


  #Récupère les préférences d'une application
  desc "Récupère les préférences d'une application d'un utilisateur"
  get ":user_id/application/:application_id/preferences" do 
    user = check_user!()
    application_id = params["application_id"]
    application = Application[:id => application_id]
    user.preferences(application_id)
  end

  #Modifie une préférence
  desc "Modifier une(des) preferecne(s)"
  put ":user_id/application/:application_id/preferences" do
    user = check_user!()
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

  #Remettre la valeure par défaut pour toutes les préférences
  desc "Remettre la valeure par défaut pour toutes les préférences"
  delete ":user_id/application/:application_id/preferences" do 
    user = check_user!()
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
end
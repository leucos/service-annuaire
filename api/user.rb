#coding: utf-8
class UserApi < Grape::API
  format :json

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
  end


  desc "Renvois le profil utilisateur si on passe le bon login/password"
  params do
    requires :login, type: String, regexp: /^[a-z]/i, desc: "Doit commencer par une lettre"
    requires :password, type: String
  end
  get do
    u = User[:login => params[:login]]
    if u and u.password == params[:password]
      u
    else
      error!("Forbidden", 403)
    end
  end

  desc "Renvois le profil utilisateur si on donne le bon id. Nécessite une authentification."
  params do
    requires :id, type: String
  end
  get "/:id" do
    User[params[:id]]
  end

  # TODO : merger ce code avec /:id => nécessite modif SSO
  desc "Renvois le profil utilisateur si on donne le bon login. Nécessite une authentification."
  params do
    requires :login, type: String
  end
  get "profil/:login" do
    result = {} 
    u = User[:login => params[:login]]
    if u
      #result[:user] = u
      p = u.profil_actif
      if p
        #result[:profil] = {:code_uai => p.etablissement.code_uai, :code_ent => p.profil.code_ent}
        result = u.to_hash.merge({:code_uai => p.etablissement.code_uai, :categories => p.profil.code_ent}) 
      end
    else
      error!("Utilisateur non trouvé", 404)
    end
    result
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
    p = params
    begin
      u = User.new()
      params.each do |k,v|
        if k != "route_info"
          begin
            u.set(k.to_sym => v)
          rescue
            error!("Validation failed", 400)
          end
        end
      end
      u.save()
    rescue Sequel::ValidationFailed
      error!("Validation failed", 400)
    end
  end

  # Même chose que post mais peut ne pas prendre des champs require
  # Renvois la ressource user complète
  desc "Modification d'un compte utilisateur"
  put "/:id" do
    u = User[params[:id]]
    if u
      params.each do |k,v|
        # Un peu hacky mais je ne vois pas comment faire autrement...
        if k != "id" and k != "route_info"
          begin
            u.set(k.to_sym => v)
          rescue
            error!("Validation failed", 400)
          end
        end
      end
      begin
        u.save()
      rescue Sequel::ValidationFailed
        error!("Validation failed", 400)
      end
    else
      error!("Utilisateur non trouvé", 404)
    end
  end

  desc "a service to search users according to certiain informations"
  # look at tests to see some examples about parameters
  get "/query/users"  do
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
  get "/:id/relations" do 
    id = params[:id]
    if !id.nil? and !id.empty?
      user = User[:id => id]
    else
      error!("Utilisateur non trouvé", 404)
    end 
    user.relations
  end

  
  # @state[not finished]
  #Il ne peut y en avoir qu'une part adulte
  #Cas d'un user qui devient parent d'élève {eleve_id: VAA60001, type_relation_id: "PAR"}
  desc "Ajout d'une relation entre un adulte et un élève"  
  post "/:user_id/relation" do
    user_id = params["user_id"]
    if User[:id => user_id].nil? 
      error!("ressource non trouvé", 404)
    end 
    eleve_id = params["eleve_id"]
    type_relation_id = params["type_relation_id"]

    if !eleve_id.nil? and !eleve_id.empty?
      if !type_relation_id.nil? and !type_relation_id.empty?
        #User[:id => user_id].add_relation(eleve_id, type_relation_id) 
        # returns {id: user_id ,relations: [{eleve_id, type_relation id}]}

        {:user_id => user_id , :eleve_id => eleve_id , :type_relation_id => type_relation_id}
      else
        error!("mauvaise requete", 400)
      end 
    else
      error!("mauvaise requete", 400) 
    end 

  end


  # @state[not finished]
  desc "Modification de la relation"
  params do
    requires :type_relation_id, type: String
    requires :eleve_id, type:String 
  end
  put "/:user_id/relation/:eleve_id" do
    user_id = params["user_id"]
    if User[:id => user_id].nil?
      error!("ressource non trouvé", 403)
    end
    eleve_id = params["eleve_id"]
    type_relation_id = !params["type_relation_id"].empty? ? params["type_relation_id"] : error!("mauvaise requete", 400)
    {:user_id => user_id, :eleve_id => eleve_id}
  end
  

  # @state[not finished]
  #Suppression de la relation (1 par adulte)
  #DEL /user/:user_id/relation/:eleve_id 
  desc "suppression d'une relation adulte/eleve"
  delete "/:user_id/relation/:eleve_id" do 
    user_id = params["user_id"]
    eleve_id = params["eleve_id"]

    if User[:id => eleve_id].nil? or User[:id => user_id].nil? #adult or eleve donnot exist
      error!("ressource non trouvé", 403)
    end 

    u = User[user_id]

    # if relation des not exist  
      #error! ("ressource non trouvé", 403)
    #else
      #delete the relation 
    #end 
    "ok"  
  end

  desc "recuperer la liste des emails"
  get "/:user_id/emails" do 
    user_id = params["user_id"]
    u = User[:id => user_id]
    if u.nil? 
      error!("ressource non trouvé", 403)
    else
      emails = u.email
      emails.map  do |email|
        {:id => email.id, :adresse => email.adresse, :academique => email.academique, :principal => email.principal}
      end 
    end 
  end

  desc "ajouter un email à l'utilisateur"
  post ":user_id/email" do
    user_id = params["user_id"]
    u = User[:id => user_id]
    if u.nil? 
      error!("ressource non trouvé", 403)
    else
      if params["adresse"].nil? or params["adresse"].empty? 
        error!("mauvaise requete", 400) 
      else 
        adresse = params["adresse"] 
      end 
      if params["academique"].nil? or params["academique"].empty? 
          academique = false 
      else
          academique = params["academique"] == "true" ? true : false 
      end 
      u.add_email(adresse, academique)
      
    end 
  end

# modifier l'adresse et le type de l'email
# l'email doit apartenir à l'utilisateur user_id
  desc "modifier un email existant"
  put ":user_id/email/:email_id" do
    user_id = params["user_id"]
    email_id = params["email_id"].to_i
    u = User[:id => user_id]
    if u.nil? or !u.email.map{|email| email.id}.include?(email_id)
      error!("ressource non trouvé", 403)
    else
      adresse = params["adresse"]
      if adresse.nil?
        error!("mauvaise requete", 400)
      else
        academique = (!params["academique"].nil?  and  params["academique"] == "true") ? true : false
        principal = (!params["principal"].nil?  and  params["principal"] == "true") ? true : false
        email = Email[:id => email_id]
        email.adresse = adresse
        email.academique = academique
        email.principal = principal 
        email.save 
      end 
    end 
  end

# supprimer un des email de l'utilisateur 
  desc "supprimer un email" 
  delete ":user_id/email/:email_id" do
    user_id = params["user_id"]
    email_id = params["email_id"].to_i
    u = User[:id => user_id]
    if u.nil? or !u.email.map{|email| email.id}.include?(email_id)
      error!("ressource non trouvé", 403)
    else
      email = Email[:id => email_id]
      email.destroy
    end   
  end

  
  #recuperer la liste des telephones qui appartien à un utilisateur 
  desc "recuperer les telephones"
  get ":user_id/telephones" do
    user_id = params["user_id"]
    u = User[:id => user_id]
    if u.nil?
      error!("ressource non trouvé", 403)
    else
      u.telephone.map{|tel| {id: tel.id, numero: tel.numero, type: tel.type_telephone_id} } 
    end
  end 
  
  #ajouter un telephone
  desc "ajouter un numero de telephone à l'utilisateur"
  params do
    requires :numero, type: String
    optional :type_telephone_id, type: String
  end
  post ":user_id/telephone"do
    user_id = params["user_id"]
    if User[:id =>user_id].nil?
      error!("ressource non trouvé", 403)
    else 
      numero = params["numero"]
      u = User[:id =>user_id]
      if !params["type_telephone_id"].nil? and ["MAIS", "PORT", "TRAV", "AUTR"].include?(params["type_telephone_id"])
        type_telephone_id = params["type_telephone_id"]
        u.add_telephone(numero, type_telephone_id )
      else       
        u.add_telephone(numero)
      end    

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
    u = User[params[:user_id]]
    error!("ressource non trouvée", 404) if u.nil?
    tel = u.telephone_dataset[params[:telephone_id]]  
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
    user_id = params["user_id"]
    u = User[:id => user_id]
    if u.nil?
      error!("ressource non trouvé", 404)
    elsif params["telephone_id"].nil? or params["telephone_id"].empty? 
      error!("mouvaise requete", 400)
    elsif !u.telephone.map{|tel| tel.id}.include?(params["telephone_id"].to_i)  
      error!("ressource non trouvé", 404)
    else
      tel = Telephone[:id => params["telephone_id"].to_i]
      tel.destroy
    end
  end


  #Récupère les préférences d'une application
  desc "Récupère les préférences d'une application d'un utilisateur"
  get ":user_id/application/:application_id/preferences" do 
    user_id = params["user_id"]
    application_id = params["application_id"]
    application = Application[:id => application_id]
    u = User[:id => user_id]
    if u.nil? or application.nil?
      error!("ressource non trouvé", 404)
    else
      #puts u.preferences(application_id).inspect
      u.preferences(application_id)
    end 

  end

  #Modifie une préférence
  desc "Modifier une(des) preferecne(s)"
  put ":user_id/application/:application_id/preferences" do
    user_id = params["user_id"]
    application_id = params["application_id"]
    application = Application[:id => application_id]
    u = User[:id => user_id]
    if u.nil? or application.nil?
      error!("ressource non trouvé", 404)
    else
      preferences  = params.select {|key, value|  (key != "route_info" and key != "user_id" and key != "application_id")  }
      #puts preferences.inspect
      # no preferences are sent
      if preferences.count == 0 
        error!("mouvaise requete", 403)
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
        error!("mouvaise requete", 403)
      end
      preferences.each do |code, value|
        param_application = ParamApplication[:code => code]
        if !param_application.nil? and param_application.application_id == application_id 
          u.set_preference(param_application.id, value)
        end                     
      end

    end
  end

  #Remettre la valeure par défaut pour toutes les préférences
  desc "Remettre la valeure par défaut pour toutes les préférences"
  delete ":user_id/application/:application_id/preferences" do 
    user_id = params["user_id"]
    application_id = params["application_id"]
    application = Application[:id => application_id]
    u = User[:id => user_id]
    if u.nil? or application.nil?
      error!("ressource non trouvé", 404)
    else
      preferences = ParamUser.filter(:user_id  => user_id).select(:param_application_id).all
      preferences.each do |paramuser|
        param_application = ParamApplication[:id => paramuser.param_application_id]
        if !param_application.nil? and param_application.application_id == application_id 
          u.set_preference(param_application.id, nil)
        end                   
      end 
    end   

  end

  # expose custom resource attribute
  get "entity/:id" do

    id = params[:id]
    user = User[:id => id]
    if user
      present user, with: API::Entities::User
    else
     error!("ressource non trouvé", 404)
    end 
  end  


end
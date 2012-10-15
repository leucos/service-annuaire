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

  
  desc "Renvois le profil utilisateur si on donne le bon login. Nécessite une authentification."
  params do
    requires :login, type: String
  end
  get "info/:login" do
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

  desc "Service de création d'un utilisateur"
  params do
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

  desc "Service spécifique au SSO"
  get "/sso_attributes_men/:login" do
    u = User[:login => params[:login]]
    if !u.nil? and !u.profil_actif.nil?
      attributes = {
        "user" => u.id,
        "UAI" => u.etablissement.code_uai,
        "ENTPersonProfils" => u.profil_actif.profil.code_national,
        "CodeNivFormation" => nil,
        "NivFormation" => nil,
        "NivFormationDiplome" => nil,
        "Filiere" => nil,
        "Specialite" => nil,
        "Enseignement" => nil,
        "Classe" => nil,
        "Groupe" => nil,
        "MatiereEnseignEtab" => nil
      }

      if u.profil_actif.profil_id == "ENS"
        attributes["Classe"] = u.enseigne_classes.map{|c| c.libelle}.join(",")
        attributes["Groupe"] = u.enseigne_groupes.map{|g| g.libelle}.join(",")
        attributes["MatiereEnseignEtab"] = u.matiere_enseigne.map{|m| m.libelle_court}.join(",")
      else
        cls = u.classe
        attributes["Classe"] = cls.nil? ? nil : cls.libelle
        attributes["NivFormation"] = cls.nil? ? nil : cls.niveau.libelle
        attributes["Groupe"] = u.groupes.map{|g| g.libelle}.join(",")
      end

      attributes
    else
      error!("Utilisateur non trouvé", 404)
    end
  end

  desc "Service spécifique au SSO"
  get "/sso_attributes/:login" do
    u = User[:login => params[:login]]
    if !u.nil? and !u.profil_actif.nil?
      attributes = {
        "login" => u.login,
        "pass" => u.password,
        "ENT_id" => u.id,
        "uid" => u.id,
        "LaclasseNom" => u.nom,
        "LaclassePrenom" => u.prenom,
        "LaclasseDateNais" => u.date_naissance,
        "LaclasseSexe" => u.sexe,
        "LaclasseAdresse" => u.adresse,
        "LaclasseCivilite" => u.civilite,
        "ENTPersonStructRattach" => u.etablissement.code_uai,
        "ENTPersonStructRattachRNE" => u.etablissement.code_uai,
        "ENTPersonProfils" => u.profil_actif.profil.code_national,
        "LaclasseEmail" => u.email_principal,
        "LaclasseEmailAca" => u.email_academique
      }

      cls = u.classe
      attributes["ENTEleveClasses"] = cls.nil? ? nil : cls.libelle
      attributes["LaclasseNomClasse"] = cls.nil? ? nil : cls.libelle
      attributes["ENTEleveNivFormation"] = cls.nil? ? nil : cls.niveau.libelle

      attributes
    else
      error!("Utilisateur non trouvé", 404)
    end
  end

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

    response = PagedQuery.new('User',columns, filter,start,length, sortcol, sortdir, search)
    response.as_json
  end

  desc "Search parents of a student that has  a specified sconet_id"
  get "/parent/eleve"  do
    nom = params["nom"].nil? ?  "" : params["nom"]
    prenom = params["prenom"].nil? ?  "" : params["prenom"]
    eleve_sconet_id = params["sconet_id"].nil? ?  "" : params["sconet_id"]
    error!("Bad Request", 400)    if eleve_sconet_id.empty?
    parents = User.join(:relation_eleve, :user_id => :id).
        filter(:eleve_id => User.select(:id).filter(:id_sconet => eleve_sconet_id), :type_relation_eleve_id => ["PERE", "MERE"]).
        select(:nom, :prenom, :login)

    if !nom.empty? 
      parents = parents.filter(:nom => nom)
    end
    if !prenom.empty? 
      parents = parents.filter(:prenom => prenom)
    end
    parents  
  end


end
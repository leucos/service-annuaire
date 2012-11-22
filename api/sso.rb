#encoding: utf-8

#coding: utf-8
class SsoApi < Grape::API
  format :json

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

  desc "Service spécifique au SSO"
  get "/sso_attributes_men/:login" do
    u = User[:login => params[:login]]
    error!("Utilisateur non trouvé", 404) if u.nil?
    profil_user = u.profil_actif
    error!("Utilisateur sans profil", 404) if profil_user.nil?

    attributes = {
      "user" => u.id,
      "UAI" => profil_user.etablissement.code_uai,
      "ENTPersonProfils" => profil_user.profil.code_national,
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

    if profil_user.profil_id == "ENS"
      attributes["Classe"] = u.enseigne_classes.map{|c| c.libelle}.join(",")
      attributes["Groupe"] = u.enseigne_groupes.map{|g| g.libelle}.join(",")
      attributes["MatiereEnseignEtab"] = u.matiere_enseigne.map{|m| m.libelle_court}.join(",")
    else
      cls = u.classes.first
      attributes["Classe"] = cls.nil? ? nil : cls.libelle
      attributes["NivFormation"] = cls.nil? ? nil : cls.niveau.libelle
      attributes["Groupe"] = u.groupes_eleves.map{|g| g.libelle}.join(",")
    end

    attributes
  end

  desc "Service spécifique au SSO"
  get "/sso_attributes/:login" do
    u = User[:login => params[:login]]
    error!("Utilisateur non trouvé", 404) if u.nil?
    profil_user = u.profil_actif
    error!("Utilisateur sans profil", 404) if profil_user.nil?

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
      "ENTPersonStructRattach" => profil_user.etablissement.code_uai,
      "ENTPersonStructRattachRNE" => profil_user.etablissement.code_uai,
      "ENTPersonProfils" => profil_user.profil.code_national,
      "LaclasseEmail" => u.email_principal,
      "LaclasseEmailAca" => u.email_academique
    }

    cls = u.classes.first
    attributes["ENTEleveClasses"] = cls.nil? ? nil : cls.libelle
    attributes["LaclasseNomClasse"] = cls.nil? ? nil : cls.libelle
    attributes["ENTEleveNivFormation"] = cls.nil? ? nil : cls.niveau.libelle

    attributes
  end

  desc "Search parents of a student who has a specific sconet_id"
  params do
    requires :id_sconet, type: Integer 
    optional :nom, type: String
    optional :prenom, type: String
  end
  # returns empty array if parent(s) is(are) not found
  get "/parent/eleve/:id_sconet"  do
    eleve = User[:id_sconet => params[:id_sconet]]
    dataset = eleve.parents_dataset
    dataset = dataset.filter(:nom => params[:nom]) if params[:nom]
    dataset = dataset.filter(:prenom => params[:prenom]) if params[:prenom]
    
    dataset.all
  end


  # TEMP : je ne sais pas si ce code sert toujours
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
end
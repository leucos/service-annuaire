#coding: utf-8
class UserApi < Grape::API
  format :json

  desc "Renvois le profil utilisateur si on passe le bon login/password"
  params do
    requires :login, type: String, regexp: /^[a-z]/i, desc: "Doit commencer par une lettre"
    requires :password, type: String
  end
  get do
    u = User[:login => params[:login], :password => params[:password]]
    if u
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
    optional :email_principal, type: String
    optional :email_secondaire, type: String
    optional :email_academique, type: String
  end
  post do
    p = params
    u = User.create(:login => p[:login], :password => p[:password], 
      :nom => p[:nom], :prenom => p[:prenom], :sexe => p[:sexe],
      :date_naissance => p[:date_naissance], :adresse => p[:adresse],
      :code_postal => p[:code_postal], :ville => p[:ville],
      :id_sconet => p[:id_sconet], :id_jointure_aaf => p[:id_jointure_aaf],
      :email_principal => p[:email_principal], :email_secondaire => p[:email_secondaire],
      :email_academique => p[:email_academique])
  end
end
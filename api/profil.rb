#encoding: utf-8

require 'grape'
class ProfilApi < Grape::API                                                                                                                                                                                     
  format :json
  prefix 'api'

  #content_type :json, "application/json; charset=utf-8"
  default_error_formatter :json
  default_error_status 400

  # Tout erreur de validation est gérée à ce niveau
  # Va renvoyer le message d'erreur au format json
  # avec le default error status
  rescue_from :all
  helpers RightHelpers 

  resource :profils do
    desc "list all profils"
    get "/" do
      authenticate!
      authorize_activites!([ACT_READ, ACT_MANAGE], Ressource.laclasse, SRV_USER)
      
      dataset = Profil.dataset 
      dataset.select(:id, :description, :code_national).naked 
    end 

    desc "list all fonctions education national" 
    get "/fonctions" do 
      authenticate!
      authorize_activites!([ACT_READ, ACT_MANAGE], Ressource.laclasse, SRV_USER)
      
      dataset = Fonction.dataset 
      dataset.select(:id, :libelle,  :description, :code_men).naked 
    end   
  end
end   

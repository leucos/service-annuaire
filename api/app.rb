#encoding: utf-8
require 'grape'
require_relative '../lib/auth_api'

class ApplicationApi < Grape::API                                                                                                                                                                                     
  prefix 'api'
  version 'v1', :using => :param, :parameter => "v"
  format :json
  #content_type :json, "application/json; charset=utf-8"
  default_error_formatter :json
  default_error_status 400
  resource :applications do 
    
    #    !important: needs to add authentiction and authorization       #
    #####################################################################
    
    desc "get all applications"
    get do
      Application.all
    end 

    #####################################################################

    desc "return application details"
    params do 
      requires :id, type: String
    end 
    get "/:id" do 
      Application[:id => params[:id]]
    end
    
    #####################################################################

    desc "create an application"
    params do
      requires :code, type:String
      optional :libelle, type:String
      optional :description, type:String
      optional :url, type:String
    end 
    post do
      app = Application.find_or_create(:id => params[:code])
      app.libelle = params[:libelle]
      app.description = params[:description]
      app.url = params[:url]
      app.save
    end 

    #####################################################################

    desc "delete an application"
    params do 
      requires :id, type: String
    end
    delete "/:id" do
      Application[:id => params[:id]].destroy
    end
    
    #####################################################################

    desc "return all application parameters"
    params do
      requires :id, type:String
    end
    get "/:id/params" do 
      app = Application[:id => params[:id]]
      if app 
        app.param_application_dataset.naked.all
      else
        error!("application n\'exist pas", 404)
      end   
    end
    #####################################################################

    desc "create parameter to the application"
    params do 
      requires :code, type:String 
      requires :preference, type:Boolean 
      requires :id, type:String 
      requires :type_param_id, type:String 
      optional :libelle, type:String 
      optional :description, type:String 
      optional :valeur_defaut, type:String
      optional :autres_valeur, type:String 
    end 
    post "/:id/params" do 
      app = Application[:id => params.id]
      if app
        app.add_parameter(params.code, params.type_param_id, params.preference, params.description, params.valeur_defaut , params.autres_valeurs)
      else 
        error!("ressource non trouvée", 404)
      end 
    end

    ##################################################################### 

    desc "delete a parameter fo an application"
    params do 
      requires :param_id, type:Integer
      requires :id, type:String 
    end

    delete "/:id/params/:param_id" do
      puts 
      param = ParamApplication[:id => params.param_id, :application_id => params.id]
      if param 
        param.destroy
      else
        error!("ressource non trouvee", 404)
      end 
    end 

    ##################################################################### 

    desc "modify a parametre" 
    params do 
      requires :param_id, type:Integer
      requires :id, type:String
    end 
    put "/:id/params/:param_id" do 
      param = ParamApplication[:id => params.param_id, :application_id => params.id]
      if param
        param.preference = params.preference if params.preference
        param.description = params.description if params.description
        param.libelle = params.libelle if params.libelle
        param.valeur_defaut = params.valeur_defaut if params.valeur_defaut
        param.autres_valeurs = params.autres_valeurs if params.autres_valeurs
        param.type_param_id = params.type_param_id if params.type_param_id
        param.save
      else
        error!("ressource non trouvee", 404) 
      end 
    end

    #####################################################################  

    desc "return parameter details" 
    params do 
      requires :param_id, type:Integer
      requires :id, type:String
    end 
    get "/:id/params/:param_id" do 
      param = ParamApplication[:id => params.param_id, :application_id => params.id]
      if param
        param
      else
        error!("ressource non trouvee", 404) 
      end 
    end

    #####################################################################

    desc "return application security keys information"
    params do 
      requires :id, type:String 
    end 
    get "/:id/keys" do
      application = Application[:id => params[:id]]
      if application
          key = ApplicationKey[:application_id => application.id]
          if key 
            {:key => key.application_key}
          else 
            {:key => ""}
          end 
      else 
        error!("ressource non trouvee", 404)
      end
    end 
    #####################################################################  

    desc "generte a new application key"
    params do 
      requires :id, type:String 
    end
    post "/:id/keys" do 
      application = Application[:id => params[:id]]
      if application
          key = AuthApi.generate_key
          # mockup generate new key algorithm
          old_key = ApplicationKey[:application_id => application.id]
          if old_key 
            #chage valeur 
            old_key.application_key = key 
            old_key.save
          else
            #create a new key 
            ApplicationKey.create(:application_id => application.id, :application_key => key)
          end 
          {:key => key, :app_id => application.id}
      else 
        error!("ressource non trouvee", 404)
      end
    end

    #####################################################################     

  end
end    

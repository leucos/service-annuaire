#encoding: utf-8

require 'grape'
class ApplicationApi < Grape::API                                                                                                                                                                                     
  prefix 'api'
  version 'v1', :using => :param, :parameter => "v"
  format :json
  #content_type :json, "application/json; charset=utf-8"
  default_error_formatter :json
  default_error_status 400
  resource :applications do 
    
    #####################################################################
    desc "get all applications"
    get do
      Application.all
    end 

    #####################################################################
    desc "get an application info"
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
        param.reference = params.reference if params.reference
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

  end
end    

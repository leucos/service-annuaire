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
    
    desc "get all applications"
    get do
      Application.all
    end 

    desc "get an application info"
    params do 
      requires :id, type: String
    end 
    get "/:id" do 
      Application[:id => params[:id]]
    end
    
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
      #Application.create(:id=> params[:code], :libelle => params[:libelle], :description => params[:descrioption], :url=> params[:url])
    end 


    desc "delete an application"
    params do 
      requires :id, type: String
    end
    delete "/:id" do
      Application[:id => params[:id]].destroy
    end 
    
  end
end    

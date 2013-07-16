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


    desc "delete a class"
    params do 
      requires :id, type: String
    end
    delete "/:id" do 
      puts delete application
    end 
    
  end
end    

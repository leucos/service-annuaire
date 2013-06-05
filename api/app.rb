#encoding: utf-8

require 'grape'
class ApplicationApi < Grape::API                                                                                                                                                                                     
  format :json

  resource :vapplications do 
    
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

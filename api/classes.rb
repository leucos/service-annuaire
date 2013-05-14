#encoding: utf-8

require 'grape'
class ClassApi < Grape::API                                                                                                                                                                                     
  format :json

  ressource :classes do 
    
    desc "get a class info"
    params do 
      requires :id, type: Integer 
    end 
    get "/:id" do 
    end 


    desc "delete a class"
    params do 
      requires :id, type:Integer
    end
    delete "/:id" do 
    end 
    
  end
end    
  
#encoding: utf-8

require 'grape'
class ClassApi < Grape::API                                                                                                                                                                                     
  format :json

  resource :classes do 
    
    desc "get all classes"
    get do
      puts "all classes" 
    end 

    desc "get a class info"
    params do 
      requires :id, type: Integer 
    end 
    get "/:id" do 
      puts "get class"
    end 


    desc "delete a class"
    params do 
      requires :id, type:Integer
    end
    delete "/:id" do 
    end 
    
  end
end    
  
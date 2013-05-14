#encoding: utf-8

require 'grape'
class RoleApi < Grape::API                                                                                                                                                                                     
  format :json
  
  resource :roles do
    desc "list all roles"
    get "/" do 
    end

    desc "create new role"
    post "/" do 
    end 

    desc "modify un role"
    put "/:role_id" do 
    end 

    desc "delete un role"
    delete "/:role_id" do 
    end 

    desc "list activities of a role"
    get "/:role_id/activities" do 
    end 
    
    desc "add activities to role"
    post "/:role_id/activities" do 
    end 

    desc "modify activities of a role"
    put "/:role_id/activities" do 
    end

    desc "delete activities of a role"
    delete "/:role_id/activities/:activitiy_id" do 
    end   
  end
end   

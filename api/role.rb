#encoding: utf-8

require 'grape'
class RoleApi < Grape::API
  prefix 'api'
  format :json
  
  default_error_formatter :json
  default_error_status 400
  
  resource :roles do
    desc "list all roles"
    get  do
      Role.naked.all
    end

    desc "create new role"
    params do
      requires :role_id, type: String
      optional :libelle, type: String
      optional :description, type: String
      
    end
    post "/" do
      # role = Role.find_or_create(:id => params[:role_id])
      # role.libelle = params[:libelle] if params[:libelle]
      # role.description = params[:description] if params[:description]
      # role.save 
      role = Role[:id => params[:role_id]]
      if role 
        role 
      else
        Role.create(:id => params[:role_id], :libelle => params[:libelle], :description => params[:description])
      end 

    end 

    desc "modify un role"
    put "/:role_id" do 
    end 

    desc "delete un role"
    delete "/:role_id" do 
      Role[:id => params[:role_id]].destroy
    end 

    desc "list activities of a role"
    params do 
      requires :role_id, type: String 
    end 
    get "/:role_id/activities" do 
      role = Role[:id => params[:role_id]]
      if role 
        role.activite_role_dataset.naked.all
      else 
        error!('Role n\'exist pas', 404)
      end 

    end 
    
    desc "add activities to role"
    post "/:role_id/activities" do
      puts params.inspect 
    end 

    desc "modify activities of a role"
    put "/:role_id/activities" do 
    end

    desc "delete activities of a role"
    delete "/:role_id/activities/:activitiy_id" do 
    end

    desc "list types of resources"
    get"/resources" do 
      Service.naked.all
    end 

  end
end   

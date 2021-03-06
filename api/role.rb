#encoding: utf-8

require 'grape'
class RoleApi < Grape::API
  prefix 'api'
  format :json
  
  default_error_formatter :json
  default_error_status 400

  helpers RightHelpers

  # => authenticate user
  #before do
    #authenticate! 
  #end 
  
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
        role.libelle = params[:libelle] if !params[:libelle].nil?
        role.description = params[:description] if !params[:description].nil?
        role.priority = params[:priority] if !params[:priority].nil?
        role.save 
      else
        Role.create(:id => params[:role_id], :libelle => params[:libelle], :description => params[:description])
      end 

    end

=begin
    desc "Return Role info."
      params do
        requires :id, type: String, desc: "role id."
      end
      route_param :id do
        get do
          Role[:id => params[:role_id]]
        end
      end
=end

    desc "get role info"
    params do 
      requires:role_id, type:String
    end 
    get "/:role_id" do 
      Role[:id => params[:role_id]]
    end    

    desc "modify a role"
    put "/:role_id" do 
      "mockup code"
    end 

    desc "delete a role"
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
        activities = role.activite_role_dataset.naked.all
        # output
        # [{"activite_id":"MANAGE","role_id":"TECH","service_id":"APP","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"CLASSE","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"DOCUMENT","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"ETAB","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"GROUPE","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"LIBRE","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"ROLE","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"USER","condition":"all","parent_service_id":"LACLASSE"}]

        # build activity hash for all resources
        # 
        resources = Service.naked.all
        length = resources.size 
        hash = {}
        resources.each do |elem|
          hash[elem[:id]] = {:resource => elem[:id], :activities => []}; 
        end 

        #{activity:'READ'}, {activity:'DELETE'}, {activity:'CREATE'}, {activity:'UPDATE'} 
        activities.each do |activity|
          hash[activity[:service_id]][:activities].push({:activity => activity[:activite_id], :condition=> activity[:condition], :parent_service => activity[:parent_service_id]})
        end 
        hash
      else 
        error!('Role n\'exist pas', 404)
      end 

    end 
    
    desc "add activities to role"
    params do
      requires  :rights , type: Hash
    end
    post "/:role_id/activities" do
      role = Role[:id => params[:role_id]]
      rights = params.rights
      service =  Service[:id => params.resource_id]
      activite = Activite[:id => params.activite_id]
      if role && service && activite
        # delete activities that correspond to the role and activity
        ActiviteRole.filter(:activite_id => activite.id, :role_id => role.id, :service_id =>  service.id).destroy
        rights.each do |r| 

          # add new activities 
          if(!r[1].condition.nil? && !r[1].parent_service_id.nil?)
            ActiviteRole.find_or_create(:activite_id => r[1].activite_id, :condition => r[1].condition, :role_id => r[1].role_id, 
              :parent_service_id => r[1].parent_service_id, :service_id => r[1].service_id)
          end 
  
        end 
      else
        error!("resource non trouvé", 404)
      end    
    end  #End post

    desc "modify activities of a role"
    put "/:role_id/activities" do 
    end

    desc "delete activities of a role"
    delete "/:role_id/activities/:activitiy_id" do

    end

    desc "list types of resources"
    get "/resources/types" do 
      Service.naked.all
    end 


    desc "list activities par role et type ressource"
    params do 
      requires :role_id, type: String 
      requires :resource_id, type: String
    end 
    get "/:role_id/activities/:resource_id" do 
      role = Role[:id => params[:role_id]]
      resource = Service[:id => params[:resource_id]]
      if role && resource  
        activities = role.activite_role_dataset.where(:service_id => resource.id).naked.all
        # output
        # [{"activite_id":"MANAGE","role_id":"TECH","service_id":"APP","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"CLASSE","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"DOCUMENT","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"ETAB","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"GROUPE","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"LIBRE","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"ROLE","condition":"all","parent_service_id":"LACLASSE"},
        #   {"activite_id":"MANAGE","role_id":"TECH","service_id":"USER","condition":"all","parent_service_id":"LACLASSE"}]

        # build activity hash for all resources

        act = []
        activities.each do |activity|
          #if activity[:activite_id] == "MANAGE" 
           # act += [
            #  {:activite_id => "READ", :role_id =>role.id,:service_id => resource.id,:condition=> activity[:condition], :parent_service_id => activity[:parent_service_id]}, 
            # {:activite_id => "CREATE",  :role_id =>role.id,:service_id => resource.id, :condition=> activity[:condition], :parent_service_id => activity[:parent_service_id]}, 
            #  {:activite_id => "DELETE",  :role_id =>role.id,:service_id => resource.id, :condition=> activity[:condition], :parent_service_id => activity[:parent_service_id]},
            #  {:activite_id => "UPDATE",  :role_id =>role.id,:service_id => resource.id, :condition=> activity[:condition], :parent_service_id => activity[:parent_service_id]}
            #  ]
          #else
            act.push(activity)
          #end 
        end
        JSON.pretty_generate(act)
      else 
        error!('Role ou ressource n\'exist pas', 404)
      end 
    end

    desc "add activities to role"
    params do
      requires :rights , type: Hash
      requires :resource_id, type: String
    end
    post "/:role_id/activities/:resource_id" do
      puts params[:resource_id]
      rights = params.rights
      rights.each do |r|  
        puts "#####################" 
        puts r[1].activite_id
        puts r[1].condition
        puts r[1].service_id
        puts r[1].role_id
        puts r[1].parent_service_id
      end 
    end

    desc "delete activities from a role" 
    params do
      requires :rights , type: Hash
      requires :resource_id, type: String
    end
    delete "/:role_id/activities/:resource_id" do

    end  



    desc "add a role to a user"
    params do 
      #requires
    end
    post "/users/:role_id/:user_id" do 

    end

  end
end   

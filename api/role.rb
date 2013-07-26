#encoding: utf-8

require 'grape'
class RoleApi < Grape::API
  prefix 'api'
  format :json
  
  default_error_formatter :json
  default_error_status 400

  helpers RightHelpers

  # => authenticate user
  # before do
  #   authenticate! 
  # end 
  
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
        resources = Service.naked.all
        length = resources.size 
        hash = {}
        resources.each do |elem|
          hash[elem[:id]] = {:resource => elem[:id], :activities => [{activity:'READ'}, {activity:'DELETE'}, {activity:'CREATE'}, {activity:'UPDATE'}]}; 
        end 

        act = {}
        i = 0 
        activities.each do |activity|
        
          # activity = "MANAGE"
          if activity[:activite_id] == "MANAGE" 
            act[activity[:service_id]] = {:activities => [
              {:activity => "READ", :condition=> activity[:condition], :parent_service => activity[:parent_service_id]}, 
              {:activity => "CREATE", :condition=> activity[:condition], :parent_service => activity[:parent_service_id]}, 
              {:activity => "DELETE", :condition=> activity[:condition], :parent_service => activity[:parent_service_id]},
              {:activity => "UPDATE", :condition=> activity[:condition], :parent_service => activity[:parent_service_id]}
              ], :resource => activity[:service_id]}
          # activity != "MANAGE"  
          else
            # First time, activity with resource = service_id does not exist 
            
            if !act.key?(act[activity[:service_id]])
              # build object 
              act[activity[:service_id]] = {:activities => [
                {:activity => "READ"}, 
                {:activity => "CREATE"}, 
                {:activity => "DELETE"},
                {:activity => "UPDATE"}
                ], :resource => activity[:service_id]}
              # modify activity  
              act[activity[:service_id]][:activities].each do |elem|
                if elem[:activity] == activity[:activite_id]
                  elem[:condition]= activity[:condition]
                  elem[:parent_service] =  activity[:parent_service_id]
                end  
              end
            else #modify activity
              act[activity[:service_id]][:activities].each do |elem|
                if elem[:activity] == activity[:activite_id]
                  elem[:condition]= activity[:condition]
                  elem[:parent_service] =  activity[:parent_service_id]
                end  
              end 
            end   
          end     
        end 
        act
        #act.merge(hash){|key, oldval, newval| newval[:activities] + oldval[:activities]}
      else 
        error!('Role n\'exist pas', 404)
      end 

    end 
    
    desc "add activities to role"
    params do
      requires  :rights , type: Hash
    end
    post "/:role_id/activities" do
      rights = params.rights

      #example 
      #role_tech.add_activite(SRV_USER, ACT_MANAGE, "all", SRV_LACLASSE)

      puts "role_id = #{params[:role_id]}"
      role = Role[:id => params[:role_id]]
      if role
        # treat data  
        rights.each do  |key, elem|
          #role_tech.add_activite(SRV_USER, ACT_MANAGE, "all", SRV_LACLASSE)
          # build matrix rights and send it to the server 
          elem.activities.each  do |droit|
            puts elem.activities
            puts elem.resource
            if droit.condition == "all"
              puts "role.add_activite(#{elem.resource},#{droit.activity},#{droit.condition}, SRV_LACLASSE)"
            elsif droit.condition == "self" 
              puts "role.add_activite(#{elem.resource},#{droit.activity},#{droit.condition}, SRV_USER)"
            elsif droit.condition == "belongs_to"
              if droit.parent_service
                puts "role.add_activite(#{elem.resource},#{droit.activity},#{droit.condition}, droit.parent_service)"
              end     
            else
              "puts do nothing"
            end 

          end 
          
        end
      else
        error!("resource non trouvé", 404)
      end   

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

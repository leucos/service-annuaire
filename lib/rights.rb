module Rights
  #------------------------------------------------------------------------#
  # Function qui récupère les droits sur une ressource de manière récursive
  # en remontant tous les ancètres
  
  # find all rights for a specific user
  # example output 
  #[{:user_id=>1324, :activite=>"DELETE", :target_class=>"CLASSE", :condition=>"belongs_to", :parent_class=>"ETAB", :parent_id => "123", :etablissement_id => "22"}, {}]
  def self.resolve_rights(user_id, etablissement_id = nil)
    rights = []

    # if user does not exists
    user = User[:id => user_id]
    if user.nil?
      return []
    end 

    if etablissement_id.nil? 
      # find user roles in all etablissements
      ds = RoleUser.filter(:user_id => user_id, :bloque => false)
    else 
      # find user roles in an etablissement with id = etablissement_id 
      ds = RoleUser.filter(:user_id => user_id, :etablissement_id => etablissement_id, :bloque => false)
    end 


    ds.each do |role_user|
      activites = ActiviteRole.filter(:role_id => role_user.role_id)
      activites.each do |act|

          case act[:parent_service_id]
            
            when  SRV_LACLASSE
              parent_id = "0"
              rights.push({:user_id => role_user[:user_id], :activite => act[:activite_id], :target_service => act[:service_id], 
                :condition => act[:condition], :parent_service => act[:parent_service_id], :parent_id => parent_id, 
                :etablissement_id => role_user[:etablissement_id]})
            
            when SRV_ETAB 
              parent_id = role_user[:etablissement_id].to_s 
              rights.push({:user_id => role_user[:user_id], :activite => act[:activite_id], :target_service => act[:service_id], 
                :condition => act[:condition], :parent_service => act[:parent_service_id], :parent_id => parent_id, 
                :etablissement_id => role_user[:etablissement_id]})
            
            when SRV_CLASSE
              # prof
              classes = user.enseigne_classes(etablissement_id) 
              classes.each do |classe| 
                rights.push({:user_id => role_user[:user_id], :activite => act[:activite_id], :target_service => act[:service_id], 
                :condition => act[:condition], :parent_service => act[:parent_service_id], :parent_id => classe[:id].to_s, 
                :etablissement_id => role_user[:etablissement_id]})
              end
              #eleve 
              classes = user.classes_eleve(etablissement_id)
              classes.each do |classe| 
                rights.push({:user_id => role_user[:user_id], :activite => act[:activite_id], :target_service => act[:service_id], 
                :condition => act[:condition], :parent_service => act[:parent_service_id], :parent_id => classe[:id].to_s, 
                :etablissement_id => role_user[:etablissement_id]})
              end 
              #parent
              user.enfants.each do |enfant|
                classes = enfant.classes_eleve(etablissement_id)
                classes.each do |classe| 
                  rights.push({:user_id => role_user[:user_id], :activite => act[:activite_id], :target_service => act[:service_id], 
                  :condition => act[:condition], :parent_service => act[:parent_service_id], :parent_id => classe[:id].to_s, 
                  :etablissement_id => role_user[:etablissement_id]})
                end 
              end
            
            #TODO: ADD Groupe, Applications, Roles, Params  #modifier 
            when SRV_GROUPE
              #prof
              groupes = user.enseigne_groupes(etablissement_id)
              groupes.each do |groupe| 
                rights.push({:user_id => role_user[:user_id], :activite => act[:activite_id], :target_service => act[:service_id], 
                :condition => act[:condition], :parent_service => act[:parent_service_id], :parent_id => groupe[:id].to_s, 
                :etablissement_id => role_user[:etablissement_id]})
              end
              #rights.push({:user_id => role_user[:user_id], :activite => act[:activite_id], :target_service => act[:service_id], 
              #  :condition => act[:condition], :parent_service => act[:parent_service_id], 
              #  :etablissement_id => role_user[:etablissement_id]})
              # eleve
              groupes = user.groupes_eleve(etablissement_id)
              groupes.each do |groupe| 
                rights.push({:user_id => role_user[:user_id], :activite => act[:activite_id], :target_service => act[:service_id], 
                :condition => act[:condition], :parent_service => act[:parent_service_id], :parent_id => groupe[:id].to_s, 
                :etablissement_id => role_user[:etablissement_id]})
              end
              
              #parent
              user.enfants.each do |enfant|
                groupes = enfant.groupes_eleve(etablissement_id)
                groupes.each do |groupe| 
                  rights.push({:user_id => role_user[:user_id], :activite => act[:activite_id], :target_service => act[:service_id], 
                  :condition => act[:condition], :parent_service => act[:parent_service_id], :parent_id => groupe[:id].to_s, 
                  :etablissement_id => role_user[:etablissement_id]})
                end 
              end
            
            #todo add groupees_libre   
            when SRV_LIBRE
              # membre
              groupes = user.groupes_libres
              groupes.each do |groupe| 
                  rights.push({:user_id => role_user[:user_id], :activite => act[:activite_id], :target_service => act[:service_id], 
                  :condition => act[:condition], :parent_service => act[:parent_service_id], :parent_id => groupe[:regroupement_libre_id].to_s, 
                  :etablissement_id => role_user[:etablissement_id]})
              end 

          
            when SRV_USER 
              rights.push({:user_id => role_user[:user_id], :activite => act[:activite_id], :target_service => act[:service_id], 
                :condition => act[:condition], :parent_service => act[:parent_service_id], :parent_id => role_user[:user_id].to_s,
                :etablissement_id => role_user[:etablissement_id]})

              # to be modified, i'am not sure if this is important    
            when SRV_APP 
              rights.push({:user_id => role_user[:user_id], :activite => act[:activite_id], :target_service => act[:service_id], 
                :condition => act[:condition], :parent_service => act[:parent_service_id], :parent_id => role_user[:user_id].to_s,
                :etablissement_id => role_user[:etablissement_id]}) 

            when SRV_ROLE
              rights.push({:user_id => role_user[:user_id], :activite => act[:activite_id], :target_service => act[:service_id], 
                :condition => act[:condition], :parent_service => act[:parent_service_id], :parent_id => role_user[:user_id].to_s,
                :etablissement_id => role_user[:etablissement_id]})  
            else 
              #do nothing  
          end     
      end
    end
    rights.uniq
    #rights.uniq!
  end
  #-------------------------------------------------------------------------------------------------------------#
  # get rights on a specific resource

  # @param user_id : utilisateur sur lequel on veut récupérer les droits
  # @param service_id ou type_ressource: service de la ressource sur laquelle on teste les droits
  # @param ressource_id : id de la ressource liée au service
  # @param initial_service_id : si pas précisé == service_id
  # sinon correspond au service sur lequel on veut connaitre les droits.
  # ex: on veut savoir si une personne a le droit de créer des utilisateurs dans un établissement
  # on fera get_activities("VAA60001", "1", "ETAB") => get activities for user VAA60001  on etablissement with id = 1 

  # get user activities on a  a ressource with ressource_id and type_ressource 
  # or on a service in the case of create (i.e.  USER)  
  def self.get_activities(user_id, ressource_id, type_ressource, service = nil)
    # Il est possible que la ressource n'existe pas
    ressource = Ressource[:id => ressource_id, :service_id => type_ressource]
    #puts "ressource=#{ressource.parent}"
    activities = []
    return activities if ressource.nil?

    #TODO modifier les droits 
    rights = resolve_rights(user_id) 
    
    #### debug ####
    ##puts rights.inspect 
    #### debug ####
    
    rights.each do |activity|

      # user has activities on himself or his resources ..  
      if activity[:condition] == "self" 
        # himself 
        if activity[:target_service] == type_ressource  && ressource_id == activity[:user_id].to_s
          activities.push(activity[:activite])

        # his resources  
        elsif activity[:target_service] == type_ressource  

        end
      
      ## belongs to condition 
      # user has activites on a service that belongs to a parent service(etablissement, classe, groupe) 
      elsif  activity[:condition] == "belongs_to" && type_ressource == activity[:target_service] 
        activities.push(activity[:activite]) if ressource.belongs_to(Ressource[:id => activity[:parent_id], :service_id => activity[:parent_service]])
      
      ## all condition ...
      # user has activites on all memebers of a service 
      elsif activity[:condition] == "all" 
        # if parent service == laclasse and type_resource == target service => push activitie in the array 
        if activity[:parent_service] == SRV_LACLASSE && ressource.service_id == activity[:target_service] 
          activities.push(activity[:activite])
        
        # important this resoulves to  manage and create 
        # create A service
        # i.e get_activities(user_id, 0, Laclasse, CLASSE) => ['Create', 'Manage']
        elsif type_ressource == activity[:parent_service] && service == activity[:target_service] && ressource_id == activity[:parent_id]
          activities.push(activity[:activite])  
        end 
      
      # for the moment it is not necessary( i don't use this role)
      elsif activity[:condition] == "parent" && ressource_id == activity[:parent_id] && type_ressource == activity[:parent_class]
        activities.push(activity[:activite])
      end

    end

    # MANAGE Activity 
    if activities.include?(ACT_MANAGE)
      return [ACT_MANAGE]
    else   
      return activities.uniq.sort
    end
  end

end 

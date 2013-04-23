module Rights
  #------------------------------------------------------------------------#
  # Function qui récupère les droits sur une ressource de manière récursive
  # en remontant tous les ancètres
  
  # find all rights for a specific user
  # example output 
  #[{:activite=>"CREATE", :subject_class=>"USER", :condition=>"belongs_to", :parent_class=>"ETAB", :parent_id=>"41"}, 
  #{:activite=>"DELETE", :subject_class=>"CLASSE", :condition=>"belongs_to", :parent_class=>"ETAB", :parent_id=>"41"},
  #{:activite=>"READ", :subject_class=>"ETAB", :condition=>"self", :parent_class=>"ETAB", :parent_id=>"41"}, 
  #{:activite=>"UPDATE", :subject_class=>"ETAB", :condition=>"self", :parent_class=>"ETAB", :parent_id=>"41"}]

  def self.find_rights(user_id)
    rights = [] 
    
    # find user roles
    ds = RoleUser.filter(:user_id => user_id, :bloque => false)
    #puts ds.all.inspect
    ds.each do |role_user|
      activites = ActiviteRole.filter(:role_id => role_user.role_id)
      activites.each do |act|
        #puts "#{{:activite => act[:activite_id], :subject_class => act[:service_id], 
          #:condition => act[:condition], :parent_class => role_user[:ressource_service_id], :parent_id => role_user[:ressource_id]}}"
        
        rights.push({:activite => act[:activite_id], :subject_class => act[:service_id], :subject_id => role_user[:user_id].to_s, 
          :condition => act[:condition], :parent_class => act[:ressource_service_id]})
      end
    end
    rights.uniq
    #rights.uniq!
  end
  #-------------------------------------------------------------------------------------------------------------#
  # get rights on a specific resource

  ##/rights/:service_name/:ressource_external_id/:user_id” ⇒ [“create_user”, “assign_role_user”, “create_classe”]
  # @param user_id : utilisateur sur lequel on veut récupérer les droits
  # @param service_id ou type_ressource: service de la ressource sur laquelle on teste les droits
  # @param ressource_id : id de la ressource liée au service
  # @param initial_service_id : si pas précisé == service_id
  # sinon correspond au service sur lequel on veut connaitre les droits.
  # ex: on veut savoir si une personne a le droit de créer des utilisateurs dans un établissement
  # on fera get_rights("VAA60001", "ETAB", 0, "USER")

  # get user activities on a  a ressource with ressource_id and type_ressource  
  def self.get_activities(user_id, ressource_id, type_ressource)
    # Il est possible que la ressource n'existe pas
    ressource = Ressource[:id => ressource_id, :service_id => type_ressource]
    #puts "ressource=#{ressource.parent}"
    activities = []
    return activities if ressource.nil?

    #TODO modifier les droits 
    rights = find_rights(user_id) 
    rights.each do |activity|
      if activity[:condition] == "self" && activity[:subject_class] == type_ressource && ressource_id == activity[:subject_id]
        activities.push(activity[:activite])
      elsif  activity[:condition] == "belongs_to" && type_ressource == activity[:subject_class] 
        # activities.push(activity[:activite]) if ressource.belongs_to(Ressource[:id => activity[:parent_id], :service_id => activity[:parent_class]])
        activities.push(activity[:activite]) if ressource.belongs_to(activity[:parent_class]) 
      elsif activity[:condition] == "all" && type_ressource == activity[:subject_class] 
        activities.push(activity[:activite]) 
      elsif activity[:condition] == "parent" && ressource_id == activity[:parent_id] && type_ressource == activity[:parent_class]
        activities.push(activity[:activite])
      end   
    end

    # MANAGE ACtiv 
    if activities.include?(ACT_MANAGE)
      return [ACT_MANAGE]
    else   
      return activities.uniq.sort
    end
  end
end 

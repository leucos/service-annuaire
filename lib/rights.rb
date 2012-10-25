#/rights/:service_name/:ressource_external_id/:user_id” ⇒ [“create_user”, “assign_role_user”, “create_classe”] 


module Rights
  rights = [] 
  def find_rights(user_id, resource_id, rights)
    role_id = RoleUser[:user_id => user_id, :ressource_id => resource_id].role_id
    if !role_id.empty? 
      activities = Activite.filter(:id => ActiviteRole(:role_id => role_id)).select(:libelle)
      activites.each do |act| 
        rights.push(act)
      end
    end
    parent_id = Ressource[:id => :resource_id].id
    if !parent_id.nil?
      find_rights(user_id, parent_id, rights)
    else
      return rights
    end
  end

  def get_rights(user_id, service_id, ressource_id)

  end
end 

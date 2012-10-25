#/rights/:service_name/:ressource_external_id/:user_id” ⇒ [“create_user”, “assign_role_user”, “create_classe”] 


module Rights
	rights = [] 


	def find_rights(user_id, resource_id,rights)

	result = RoleUser[:user_id => user_id, :ressource_id => ressource_external_id].select(:role_id)


	if !result.empty? rights.push[:activite[:id => ActiviteRole[role_id]]]
	  parent_id = Ressource[:id_extern => :resource_external_id]
	  find_rights(user_id, parent_id,rights) if !parent_id.nil?
	  return rights
	end 
end 

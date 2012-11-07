module Rights
  # Function qui récupère les droits sur une ressource de manière récursive
  # en remontant tous les ancètres
  def self.find_rights(user_id, ressource, initial_service_id, rights)
    role_user = RoleUser[:user_id => user_id, :ressource_id => ressource.id, :ressource_service_id => ressource.service_id]
    if role_user 
      activites = ActiviteRole.filter(:role_id => role_user.role_id, :service_id => initial_service_id)
      activites.each do |act|
        #puts "rights=#{act[:activite_id]}"
        rights.push(act[:activite_id])
      end
    end
    if ressource.parent
      #puts "parent=#{ressource.parent.inspect}"
      find_rights(user_id, ressource.parent, initial_service_id, rights)
    end

    rights.uniq!
  end

  ##/rights/:service_name/:ressource_external_id/:user_id” ⇒ [“create_user”, “assign_role_user”, “create_classe”]
  # @param user_id : utilisateur sur lequel on veut récupérer les droits
  # @param service_id : service de la ressource sur laquelle on teste les droits
  # @param ressource_id : id de la ressource liée au service
  # @param initial_service_id : si pas précisé == service_id
  # sinon correspond au service sur lequel on veut connaitre les droits.
  # ex: on veut savoir si une personne a le droit de créer des utilisateurs dans un établissement
  # on fera get_rights("VAA60001", "ETAB", 0, "USER")
  def self.get_rights(user_id, service_id, ressource_id, initial_service_id = service_id)
    # Il est possible que la ressource n'existe pas
    ressource = Ressource[:id => ressource_id, :service_id => service_id]
    #puts "ressource=#{ressource.parent}"
    return [] if ressource.nil?
    rights = []
    find_rights(user_id, ressource, initial_service_id, rights)
    return rights
  end
end 

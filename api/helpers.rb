module RightHelpers
  def authorize_activites!(activites, ressource, service_id = ressource.service_id)
  # Récupère la session
  # En cherchant d'abord dans l'en-tête
  # Puis dans les cookies
  # Puis enfin dans les paramètres GET/POST
  session = ! cookies[:session].nil? ? cookies[:session] : params[:session]
  if  session.nil?
    error!("Pas de droits", 403)
  end 
  # find session in radis
  user_id = AuthSession.get(session)
  if !user_id.nil?
    rights = Rights.get_rights(user_id, ressource.service_id, ressource.id, service_id)
    authorized = false
    activites.each do |act|
      if rights.include?(act)
        authorized = true
      end  
    end
    error!("Pas de droits", 403) if !authorized  
  else
    error!("Pas de droits", 403)
  end 
  # Une fois qu'on a la session, on doit récupérer l'utilisateur lié à cette session
  # Soit via l'api d'authentification ou directement en utilisant Redis 
  # (attention a bien mettre à jour le time to live)

  #rights = Rights.get_rights()
  #error!("Pas les droits", 403) unless rights.include?(activites)
  end
end
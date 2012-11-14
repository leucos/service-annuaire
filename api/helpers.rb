#encoding: utf-8

module RightHelpers
  def authorize_activites!(activites, ressource, service_id = ressource.service_id)
    # Récupèration de la session
    # En cherchant d'abord dans l'en-tête
    session = request.env[AuthConfig::HTTP_HEADER] if request.env[AuthConfig::HTTP_HEADER]
    # Puis dans les cookies
    session = cookies[:session_key] if cookies[:session_key]
    # Puis enfin dans les paramètres GET/POST
    session = params[:session_key] if params[:session_key]

    error!("Clé de session introuvable", 403) if  session.nil?

    # Une fois qu'on a la session, on doit récupérer l'utilisateur lié à cette session
    user_id = AuthSession.get(session)
    if !user_id.nil?
      # Et on teste ses droits sur la ressource
      rights = Rights.get_rights(user_id, ressource.service_id, ressource.id, service_id)
      #puts "rights user_id=#{user_id}, service_id=#{ressource.service_id}, ressource=#{ressource.id}, service_id=#{service_id }=#{rights}"
      authorized = false
      # Si un des droits renvoyé correspond à une des activités passé en paramètre
      # c'est bon
      if activites.respond_to?(:each)
        activites.each do |act|
          authorized = true if rights.include?(act)
        end
      else
        authorized = true if rights.include?(activites)
      end
      error!("Pas de droits", 403) if !authorized  
    else
      error!("Clé de session=#{session} non valide", 403)
    end
  end
end
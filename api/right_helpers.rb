#encoding: utf-8

module RightHelpers
  
  def current_user
    # Récupèration de la session

    # En cherchant d'abord dans les cookies
    session = cookies[:session_key] if cookies[:session_key]
    # Puis dans les paramètres GET/POST
    session = params[:session_key] if params[:session_key]
    # Puis enfin dans l'en-tête 
    # comme ça si on veut se faire passer pour quelqu'un, on change juste le header et pas les requètes
    # Technique de Daniel ;)
    # TODO se connecter par CAS server
    session = request.env[AuthConfig::HTTP_HEADER] if request.env[AuthConfig::HTTP_HEADER] 
    user_id = AuthSession.get(session)
    if !user_id.nil?
      @current_user = User[:id => user_id]
    else 
      @current_user = nil
    end
    @current_user  
  end

  # Because we have tow types of usage to our services 
  # 1) usage with users like ( admin laclasse, admin etablissemenet, ...)
  # 2) usage with applications that need to consume some of our api's 
  # =>  CAS server:  needs to access to sso Api 
  # =>  Gestion document : needs to consume some user api's
  # =>  Other application...( cahier de text, Blog)
  # =>  We have to soluations:  use separate apis groups ( public(application), private(users)) 
  # this is a function to authenticate users 
  def authenticate!
    error!('Non authentifié', 401) unless current_user
  end

  def authenticate_app!
    # fo
    session = cookies[:session_key] if cookies[:session_key]
    session = request.env["HTTP_SESSION_KEY"] if request.env["HTTP_SESSION_KEY"]
    id = nil 
    id = AuthSession.get(session)
    puts session
    error!('Non authentifié', 401) unless id
  end 


  def authorize_activites!(activites, ressource, service = nil)
      if current_user
      # Et on teste ses droits sur la ressource
      activities = Rights.get_activities(current_user.id, ressource.id, ressource.service_id, service)
      #puts "rights user_id=#{user_id}, service_id=#{ressource.service_id}, ressource=#{ressource.id}, service_id=#{service_id }=#{rights}"
      authorized = false
      # Si un des droits renvoyé correspond à une des activités passé en paramètre
      # c'est bon
      if activites.respond_to?(:each)
        activites.each do |act|
          authorized = true if activities.include?(act)
        end
      else
        authorized = true if activities.include?(activites)
      end
      error!("Non authorizé", 403) if !authorized  
    else
      error!("Non authentifié: clé de session=#{session} non valide", 401)
    end
  end
end
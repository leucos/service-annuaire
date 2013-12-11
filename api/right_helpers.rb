#encoding: utf-8

module RightHelpers
  
  # the authentication works only using a cas server
  # the Cas server sends a cookie(CASTGC) and stores its value in redis server
  # in order to this method to work, api server must have access to redis server
  # to check the cookie value in redis
  def current_user
    # Récupèration de la session

    # Search for CASTGC cookie 
    if cookies[:CASTGC]
      session = cookies[:CASTGC]
      # session_key is only for test 
    elsif params[:session_key] 
      session = params[:session_key]
    elsif request.env[AuthConfig::HTTP_HEADER] 
      #session = request.env[AuthConfig::HTTP_HEADER]
    else
      session = nil
    end
    #puts session 
    # 
    user_login = AuthSession.get(session)
    puts user_login 
    if !user_login.nil?
      @current_user = User[:login => user_login]
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
    # first we must separate services(apis) and
    # rewrite authenticate application method
    # application is authenticated by an api_key and api_id in the simplist scenario
    # for more security we may sign the request like in amazon authentication
    # api_key is sent as a request parameter or as a header
    # i think we must send api_id in the request
    # Todo:  use APIAuth to authenticate applications 

    #puts request.inspect 
  
    session = params[:api_key] if params[:api_key]
    session = request.env["HTTP_API_KEY"] if request.env["HTTP_API_KEY"]
    session.nil? ? app_id = nil : app_id = AuthSession.get(session)
    puts app_id 
    error!('Non authentifié', 401) unless app_id
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
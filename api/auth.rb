#encoding: utf-8

require 'grape'
class AuthApi < Grape::API                                                                                                                                                                                     
  format :json
  
  resource :auth do 
    # POST /auth
    # { id: "vaa60001" }
    # res 200:
    # { "id": "ERQASvfBG", "user_id": "VAA60001" }
    # res 401:
    # { "code": 0, "message": "authorization invalid"}
    desc "create a new session"
    params do
      requires :user_id, type: String
    end     
    post do
      #puts params.inspect
      # user can have only one session
      # todo : check that user exists ?
      key = AuthSession.create(params[:user_id])
      {:session_key => key, :user_id => params[:user_id]}    
    end

    # GET /auth/:session_key
    # res 200:
    # { "session_key": "ERQASvfBG", "user_id": "VAA60001" }
    # res: 40x:
    # { "code": 12, "message": "blahcl" }
    desc "get session info"
    params do
      requires :session_key, type: String
    end 
    get "/:session_key" do
      value = AuthSession.get(params[:session_key])
      error!("ResourceNotFound", 404) if value.nil?
      
      {:session_key => params[:session_key], :user_id => value}
    end


    # DELETE /auth/:session_key
    desc "Delete an existing session."
    params do
      requires :session_key, type: String
    end
    delete "/:session_key" do
      value = AuthSession.get(params[:session_key])
      error!("ResourceNotFound", 404) if value.nil?
      
      begin
        AuthSession.delete(params[:session_key])
      rescue AuthSession::UnauthorizedDeletion => e
        error!("Pas le droit de supprimer les sessions stockées", 403)
      end
    end

  # services for login and logout
  # login , logout , and get Logged User by the Session  
    desc "Login and create a new session if parameters are valide"
    params do 
      requires :login, type: String, regexp: /^[a-z]/i, desc: "Doit commencer par une lettre"
      requires :password, type: String
    end
    post "/login" do 
      #puts params.inspect
      # user can have only one session
      # todo : check that user exists ?
      u = User[:login => params[:login]]
      if u and u.password == params[:password]    
        key = AuthSession.create(u.id)
        {:session_key => key, :user => u}
      else
        error!("ResourceNotFound", 404)
      end 
    end

    desc "logout and delete the user session" 
    params do 
      requires :session_key, type:String
    end
    post "/logout" do 
      value = AuthSession.get(params[:session_key])
      error!("ResourceNotFound", 404) if value.nil?
      
      begin
        AuthSession.delete(params[:session_key])
      rescue  AuthSession::UnauthorizedDeletion => e
        error!("Pas le droit de supprimer les sessions stockées", 403)
      end
    end

    desc "get Logged User"
    params do 
      requires :session_key, type:String 
    end
    get "/user/:session_key" do 
      #return User[:user_id] where user_id correspond to sessio_key
      value = AuthSession.get(params[:session_key])
      error!("ResourceNotFound", 404) if User[:id => value].nil?
      u = User[:id => value]
      {:session_key => params[:session_key], :user => u}
    end     
  end


end
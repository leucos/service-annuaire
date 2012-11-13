require 'grape'
class AuthApi < Grape::API                                                                                                                                                                                     
  format :json
  
  # POST /auth
  # { id: "vaa60001" }
  # res 200:
  # { "id": "ERQASvfBG", "user": "vaa60001" }
  # res 401:
  # { "code": 0, "message": "authorization invalid"}
  desc "create a new session"
  params do
    requires :id, type: String
  end     
  post do
    # user can have only one session
    # todo : check that user exists ?
    key = AuthSession.new(params[:id])
    {"key" => key, "user" => params[:id]}    
  end

  #GET /auth/:session_key
    #res 200:
      #{ "id": "ERQASvfBG", "user": "vaa60001" }
    #res: 40x:
      #{ "code": 12, "message": "blahcl" }
  desc "get session info"
  params do
    requires :session_key, type: String
  end 
  get "/:session_key" do
    value = AuthSession.get(params[:session_key])
    error!("ResourceNotFound", 404) if value.nil?
    
    AuthSession.expire(params[:session_key], 3600)
    {"key" => params[:session_key], "user" => value}
  end


  # DELETE /auth/:session_key
  desc "Delete an existing session."
  params do
    requires :session_key, type: String
  end
  delete "/:session_key" do
    value = AuthSession.get(params[:session_key])
    error!("ResourceNotFound", 404) if value.nil?
      
    AuthSession.delete(params[:session_key])
  end
end
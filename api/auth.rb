#encoding: utf-8

require 'grape'
class AuthApi < Grape::API                                                                                                                                                                                     
  format :json
  
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
end
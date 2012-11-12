require 'grape'
class AuthApi < Grape::API                                                                                                                                                                                     
	#prefix 'api'
	format :json

=begin
  before do
    # puts '---------recieved request ----------'
    # request.env.each do |k, v|
    #   puts "#{k}=#{v}"
    # end
    #puts request.inspect
    access_id = ApiAuth.access_id(request)
    #puts "access_id #{access_id}"
    begin 
      secret_key = Apiconfig::API_KEY_STORE[access_id]
      #puts "secret_key #{secret_key}"
    rescue
      error!("AuthenticationFailed", 403)
    end  
    signed_request = request
    # authenticate user request
    error!("AuthenticationFailed", 403) unless ApiAuth.authentic?(signed_request, secret_key)
  end 
=end
  
  #POST /api/authsession
  	#{ id: "vaa60001" }
		#res 200:
			#{ "id": "ERQASvfBG", "user": "vaa60001" }
		#res 401:
			#{ "code": 0, "message": "authorization invalid"}
	desc "create a new session", {
	  :params => {
	    "id" => { :description =>"id", :required => true }
	  }
	}			
  post "authsession" do
  	id = params[:id]
    if id.nil?
    	error!("Bad Request:InvalidQueryParameterValue", 400)
    else
      # user can have only one session
      key = AuthSession.new(id)
      {"key" => key, "user" => id}    
    end  
  end

  #GET /api/authsession/session_key
		#res 200:
			#{ "id": "ERQASvfBG", "user": "vaa60001" }
		#res: 40x:
			#{ "code": 12, "message": "blahcl" }
	desc "get session info", {
	  :params => {
	    "session_key" => {:description =>"session key", :required => true }
	  }
	}		
  get "authsession/:session_key" do
  	value = AuthSession.get(params[:session_key])
    if !value.nil?
      AuthSession.expire(params[:session_key], 3600)
      {"key" => params[:session_key], "user" => value}
    else
      error!("ResourceNotFound", 404)
    end
  end


  # DELETE /api/authsession/:session_key
	desc "Delete an existing session.", {
	  :params => {
	    "session_key" => { :description =>"session key", :required => true }
	  }
	}
	delete "authsession/:session_key" do
	  value = AuthSession.get(params[:session_key])
    if !value.nil?
      AuthSession.delete(params[:session_key])
    else
      error!("ResourceNotFound", 404)
    end
	end


end
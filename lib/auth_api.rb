require 'base64'
require 'cgi'
# openssl is better than ruby-hmac and we can use sha2 instead for encrypting 
#require 'hmac-sha1'
require 'openssl'
require 'net/http'


class  AuthApi 

	def initialize
		
	end

	# une fonction pour generer une clé de 512 bits 
	def self.generate_key
		"generate key called"
		random_bytes = OpenSSL::Random.random_bytes(256)
		Digest::SHA2.new(256).digest(random_bytes)
      	Base64.encode64(Digest::SHA2.new(256).digest(random_bytes))
	end   


	# une fonction pour encrypter une requete  
	def self.servicecall(uri,service, args, secret_key, app_id) 
	   	timestamp = Time.now.getutc.strftime('%FT%T')
		canonical_string = uri + '/' +  service +'?'

		#sort hash 
		parameters = Hash[args.sort]
	   	canonical_string += parameters.collect{|key, value| [key.to_s, CGI::escape(value.to_s)].join('=')}.join('&')
	   	canonical_string += ';' 
	   	canonical_string += timestamp
	   	canonical_string += ';'
        canonical_string += app_id

        puts canonical_string

	    digest = OpenSSL::Digest::Digest.new('sha1')
		digested_message = Base64.encode64(OpenSSL::HMAC.digest(digest, secret_key, canonical_string))
	    
	    query = args.collect{|key, value| [key.to_s, CGI::escape(value.to_s)].join('=')}.join('&')

	    temp_args = {}
	    temp_args['app_id'] = app_id
	    temp_args['timestamp'] = timestamp
	    temp_args['signature'] = digested_message

	    #  puts "signed message "
	    #  puts temp_args['signature'] 

	    signature = temp_args.collect{|key, value| [key.to_s, CGI::escape(value.to_s)].join('=')}.join(';').chomp

	    url = uri + '/' + service + '?' + query +";"+ signature
	    Net::HTTP.get(URI.parse(url))
	end

	def self.sign(uri,service, args, secret_key, app_id)
		timestamp = Time.now.getutc.strftime('%FT%T')
		canonical_string = uri + '/' +  service +'?'

		#sort hash 
		parameters = Hash[args.sort]
	   	canonical_string += parameters.collect{|key, value| [key.to_s, CGI::escape(value.to_s)].join('=')}.join('&')
	   	canonical_string += ';' 
	   	canonical_string += timestamp
	   	canonical_string += ';'
        canonical_string += app_id

        puts canonical_string

	    digest = OpenSSL::Digest::Digest.new('sha1')
		digested_message = Base64.encode64(OpenSSL::HMAC.digest(digest, secret_key, canonical_string))
	    
	    query = args.collect{|key, value| [key.to_s, CGI::escape(value.to_s)].join('=')}.join('&')

	    temp_args = {}
	    temp_args['app_id'] = app_id
	    temp_args['timestamp'] = timestamp
	    temp_args['signature'] = digested_message

	    #  puts "signed message "
	    #  puts temp_args['signature'] 

	    signature = temp_args.collect{|key, value| [key.to_s, CGI::escape(value.to_s)].join('=')}.join(';').chomp

	    url = uri + '/' + service + '?' + query +";"+ signature
	    return url
	end

	# returns uri of the rack request 
	def self.url(request)
        url = request.scheme + "://"
        url << request.host
        if request.scheme == "https" && request.port != 443 ||
           request.scheme == "http" && request.port != 80
          url << ":#{request.port}"
        end

        url << request.path
        url
    end

	def self.authenticate(request)
	    # get the liste of all parameters
	    parameters = request.query_string()
	   
		principal_parameters = request.params
	    
	    timestamp = principal_parameters["timestamp"]

	    signature = principal_parameters["signature"]
	    
	    app_id = principal_parameters["app_id"]
	   	
	   	app_key = ApplicationKey[:application_id => app_id]

	    
	    if app_key
		    principal_parameters.reject! {|k,v| (k == "app_id" || k == "timestamp" || k == "signature" )}
		    # rebuild string
		    canonical_string = url(request) + '?'
		    canonical_string += Hash[principal_parameters.sort].collect{|key, value| [key.to_s, CGI::escape(value.to_s)].join('=')}.join('&')
		    canonical_string += ';' 
		   	canonical_string += timestamp
		   	canonical_string += ';'
	        canonical_string += app_id

	        #puts "application key in database"
	        #puts app_key.application_key

	        #puts "calculated canonical string"
	        #puts canonical_string
	        ## resign messsage
	        digest = OpenSSL::Digest::Digest.new('sha1')
			signed_message = Base64.encode64(OpenSSL::HMAC.digest(digest, app_key.application_key.chomp, canonical_string))
			#puts "signed_message: #{signed_message}"
			#puts "signature #{signature}"

			if signature.chomp == signed_message.chomp
				return true 
			else 
				return false 
			end
		else 
			return false 
		end
	end 	

end 
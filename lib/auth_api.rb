require 'base64'
require 'cgi'
# openssl is better than ruby-hmac and we can use sha2 instead for encrypting 
#require 'hmac-sha1'
require 'openssl'
require 'net/http'


class  AuthApi 

	def initialize()
		@entrypoint = 'http://localhost:9292/api/app'
		@accesskey = 'NYczonwTxv'
		@secretkey = 'x4whvXnG7cCOBiNBoi1r'
	end

	# une fonction pour generer une clé de 512 bits (OK)
	def generate_key()
		random_bytes = OpenSSL::Random.random_bytes(512)
		Digest::SHA2.new(512).digest(random_bytes)
      	Base64.encode64(Digest::SHA2.new(512).digest(random_bytes))
	end   

	def servicecall(service, args)
		# Example request 
		# GET /api/app/users/VAA60000?expand=true;accesskey=NYczonwTxv;timestamp=2013-11-29T12%3A15%3A21;signature=GKLAiknAqOK3e0NIVNwuhCAL15U%3D
		# /api/app/users/VAA60000?expand=true;accesskey=NYczonwTxv;timestamp=2013-11-29T15%3A40%3A38;signature=signature
	   
	    timestamp = Time.now.getutc.strftime('%FT%T')
	    message = @accesskey + service + timestamp
	    digest = OpenSSL::Digest::Digest.new('sha1')
	    digested_message = Base64.encode64(OpenSSL::HMAC.digest(digest, @secretkey, message))
	    #hmac = HMAC::SHA1.new(@secretkey)
	    #hmac.update(message)
	    #digest = hmac.digest()

	    args['accesskey'] = @accesskey
	    args['timestamp'] = timestamp
	    args['signature'] = digested_message

	    puts args['signature'] 

	    query = args.collect do |key, value|
	        [key.to_s, CGI::escape(value.to_s)].join('=')
	    end.join(';')

	    url = @entrypoint + '/' + service + '?' + query
	    Net::HTTP.get(URI.parse(url))
	end

	def sign(request, key)
		headers = Headers.new(request)
        canonical_string = headers.canonical_string
     	digest = OpenSSL::Digest::Digest.new('sha1')
     	b64_encode(OpenSSL::HMAC.digest(digest, secret_key, canonical_string))
	end


	def authenticate(request, signature)
	end  
end 
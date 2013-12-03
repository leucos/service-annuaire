#!ruby
#coding: utf-8

#require_relative '../helper'

require_relative '../../lib/auth_api'

describe "ApiAuth" do

  it "should generate a 512 key successfully" do 
    secret = AuthApi.new.generate_key
    puts secret 
  end 
 
  it "Should send a signed request" do
    api_auth = AuthApi.new
    api_auth.servicecall('users/VAA60000', {expand:true})
  end


  it "Should authenticated based on signature" do 
  	api_auth = AuthApi.new 
  	api_auth.authenticate 
  end

  it "Hmac ruby equals Hmac OpenSSl"

  end  

end 
#!ruby
#coding: utf-8

#require_relative '../helper'

require_relative '../../lib/auth_api'

describe "ApiAuth" do

  it "should generate a 512 key successfully" do 
    secret = AuthApi.generate_key
    puts secret 
  end 
 
  it "Should  get true for a correctly signed request" do
  	uri = 'http://localhost:9292/api/app'
  	app_id = 'DOC'
  	secret_key = "uVHdU5+Py5bAVCddvIe0QQYArCUtkSJwR8Prg0zLYgJ6b" 
    AuthApi.servicecall(uri, 'signed', {:expand => true, :name =>"bashar"},secret_key, app_id)
    # prints true 
  end

  it "should retrun false for non authorized request" do 
	uri = 'http://localhost:9292/api/app'
  	app_id = 'DOC'
  	secret_key = "uVHdU5+Py5bAVCddvIe0Qqdfqdfdfqsdfqsdf" 
    AuthApi.servicecall(uri, 'signed', {:expand => true, :name =>"bashar"},secret_key, app_id)
    # prints false
  end

end 
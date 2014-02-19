#!ruby
#coding: utf-8

#require_relative '../helper'

require_relative '../../lib/auth_api'

describe "ApiAuth" do

  it "should generate a 512 key successfully" do 
    #secret = AuthApi.generate_key
    #puts secret 
  end 
 
  it "Should  get true for a correctly signed request" do
  	uri = 'http://localhost:9292/api/app'
  	app_id = 'DOC'
  	secret_key = "zdBLXa7A678cumXgbjVSR4EFbDPSbwO1hUvV1eIpU5g=" 
    puts secret_key
    service = 'users/liste/'
    (1..100).each do |id|
      service += "VAA60001;" 
    end

    response = AuthApi.servicecall(uri, service, {},secret_key, app_id)
    puts response.inspect
    # prints true 
  end

  it "should post a signed request" do 
    uri = 'http://localhost:9292/api/app'
    app_id = 'DOC'
    secret_key = "zdBLXa7A678cumXgbjVSR4EFbDPSbwO1hUvV1eIpU5g=" 
    puts secret_key
    service = 'users/liste/'
    (1..100).each do |id|
      service += "VAA60001;" 
    end
    signed = AuthApi.sign(uri, service, {},secret_key, app_id)
    Net::HTTP.post(URI.parse(signed), {:ids => service})

  it "should retrun false for non authorized request" do 
	uri = 'http://localhost:9292/api/app'
  	app_id = 'DOC'
  	secret_key = "uVHdU5+Py5bAVCddvIe0Qqdfqdfdfqsdfqsdf" 
    puts secret_key
    response = AuthApi.servicecall(uri, 'users/VAA60000', {:expand => true, :name =>"bashar"},secret_key, app_id)
    puts response.inspect 
    # prints false
  end

end 
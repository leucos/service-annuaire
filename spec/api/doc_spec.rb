#coding: utf-8
require_relative '../helper'

describe DocsApi do
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file("config.ru").first
  end

  it "return user profile when giving good id" do
    u = create_test_user()
    get("/api/app/users/#{u.id_ent}").status.should == 200
  end

  it "return http 403 when giving wrong login/password" do
    # There is no test user
    get('api/app/users/liste/VAA60000;VAA60001').status.should == 200
    get('api/app/users/liste/').status.should == 404
  end
end

#encoding: utf-8

require_relative '../helper'


# test the authentication api without signing the request
# must comment before do block in auth.rb file 
# to pass test without singing
describe AlimentationApi do
 include Rack::Test::Methods

  def app
    Rack::Builder.parse_file("../../config.ru").first
  end

  # to do test with real data

  before :all do
    # load test data for test etablissement "0690078K"
    get('/alimentation/load/etablissement/0690078K')
    @data = JSON.parse(last_response.body)
    puts @data["etablissement"].first 
  end

  after :all do
    # empty alimented etablissement data
  end

  it "should feed the database with received data correctly" do 
    #sync mef 
    #sync mat 
    #sync fonctions
    # @data.each 
      #post('/alimentation/recieve',:type_import => "Complet", :uai => "0690078K",:type_data =>"DETTACHEMENT", :data => @data[])
  end 

  # problem to test with real data
  it "accepts only alimentation requests with good parameters" do
    post('/alimentation/recieve',:param => "some value").status.should == 400
    post('/alimentation/recieve',:type_import => "Complet", :uai => "12345",:type_data =>"DETTACHEMENT").status.should == 400
    JSON.parse(last_response.body)["error"].should == "missing parameter: data"
  end

  it "synchronize mef educ nat" do
    get("/alimentation/sync_mef").status.should == 200
    last_response.body.should == "Mef syncronized successfully"
  end

  it "synchronize matieres" do
    get("/alimentation/sync_mat").status.should == 200
    last_response.body.should == "Matieres syncronized successfully"  
    #delete("/auth/#{session}").status.should == 200
    #get("/auth/#{session}").status.should == 404
  end

  it "synchronize the fonctions" do
    get("/alimentation/sync_fonc").status.should == 200
    last_response.body.should == "Fonctions syncronized successfully"
  end
end
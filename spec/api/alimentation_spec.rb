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
    #etablissement du test
    @etablissement_uai = "0690078K"
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

=begin
  it "synchronize mef educ nat", :broken => true do
    get("/alimentation/sync_mef").status.should == 200
    last_response.body.should == "Mef syncronized successfully"
  end

  it "synchronize matieres", :broken => true do
    get("/alimentation/sync_mat").status.should == 200
    last_response.body.should == "Matieres syncronized successfully"  
    #delete("/auth/#{session}").status.should == 200
    #get("/auth/#{session}").status.should == 404
  end

  it "synchronize the fonctions" , :broken => true do
    get("/alimentation/sync_fonc").status.should == 200
    last_response.body.should == "Fonctions syncronized successfully"
  end


  it "empty an aliemented etablissement" do
    etablissement_uai = "0690078K" 
    get("alimentation/empty/etablissement/#{etablissement_uai}").status.should == 200
    # test empty etablissement 
    Etablissement[:code_uai => etablissement_uai].should == nil
    # test empty regroupements
    # test empty user profiles 
    # test empty user regroupement
  end 
   
  it "synchronize an etablissement and empty an alimented etablissement" do
    #etablissement_uai = "0690078K"
    get("alimentation/aliment/etablissement/#{etablissement_uai}").status.should == 200
    result = JSON.parse(last_response.body)
    puts result
    #get("alimentation/empty/etablissement/#{etablissement_uai}").status.should == 200
  end
  
  it "gets details from server about alimentation process", :broken => true do 
    #etablissement_uai = "0690078K"
    types = ["bilan_comptes", "bilan_regroupements"]
    get("/alimentation/bilan/#{types[0]}/#{@etablissement_uai}").status.should == 200 
    bilan_comptes = JSON.parse(last_response.body)
    bilan_comptes.should_not == {}
    get("/alimentation/bilan/#{types[1]}/#{@etablissement_uai}").status.should == 200 
    bilan_regroupement = JSON.parse(last_response.body)
    bilan_regroupement.should_not == {}
  end
=end
  it "alimentation should have the same results as the bilan" do
    # aliment etablissement
    get("alimentation/aliment/etablissement/#{@etablissement_uai}").status.should == 200
    result = JSON.parse(last_response.body) 
     
    types = ["bilan_comptes", "bilan_regroupements"]
    get("/alimentation/bilan/#{types[0]}/#{@etablissement_uai}").status.should == 200 
    bilan_comptes = JSON.parse(last_response.body)
    #test results
    bilan_comptes[0]["ELEVE"][0]["nb"].to_i.should == result["eleves"].to_i
    bilan_comptes[1]["PARENT"][1]["nb"].to_i.should == result["parent"].to_i
    bilan_comptes[2]["PERSEDUCNAT"][1]["nb"].to_i.should == result["pers_educ_nat"].to_i

    get("/alimentation/bilan/#{types[1]}/#{@etablissement_uai}").status.should == 200 
    bilan_regroupement = JSON.parse(last_response.body)
    bilan_regroupement[0]["CLASSES"].count.should == (result["classes"].nil? ? 0 : result["classes"])
    bilan_regroupement[1]["GROUPES"].count.should == (result["groupes"].nil? ? 0 : result["groupes"])
    
  end  

end
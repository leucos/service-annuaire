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
    #@etablissement_uai = "0690078K"
    @etablissement_uai = "0690002C"
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


  it "synchronize mef educ nat", :broken => true do
    get("/alimentation/sync_mef").status.should == 200
    JSON.parse(last_response.body)["niveaux"].should == Niveau.count
  end

  it "synchronize matieres", :broken => true do
    get("/alimentation/sync_mat").status.should == 200  
    JSON.parse(last_response.body)["matieres"].should == MatiereEnseignee.count
    #get("/auth/#{session}").status.should == 404
  end

  it "synchronize the fonctions" , :broken => true do
    get("/alimentation/sync_fonc").status.should == 200
    JSON.parse(last_response.body)["fonctions"].should == Fonction.count
  end

=begin
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
  
  it "gets details(bilan) from server about alimentation process", :broken => true do 
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
  it "alimentation should be correct" do

    #TODO: test that received records number corresponds to mysql inserts and modifictioans
    # test the validity of data (e.x name is string not a character)
    # The big Question
    # aliment etablissement
    get("alimentation/aliment/etablissement/#{@etablissement_uai}").status.should == 200
    #result = JSON.parse(last_response.body)
    puts last_response.body 
     
    types = ["bilan_comptes", "bilan_regroupements"]
    get("/alimentation/bilan/#{types[0]}/#{@etablissement_uai}").status.should == 200 
    bilan_comptes = JSON.parse(last_response.body)
    
    #test comptes info
    bilan_comptes[0]["ELEVE"][0]["nb"].to_i.should == ProfilUser.where(:profil_id => 'ELV', 
      :etablissement_id => Etablissement[:code_uai => @etablissement_uai].id).count
    bilan_comptes[1]["PARENT"][1]["nb"].to_i.should ==  ProfilUser.where(:profil_id => 'TUT', 
      :etablissement_id => Etablissement[:code_uai => @etablissement_uai].id).count
    # i can not test the number of profs
    bilan_comptes[2]["PERSEDUCNAT"][1]["nb"].to_i.should == ProfilUser.where(:profil_id => 'ENS', 
      :etablissement_id => Etablissement[:code_uai => @etablissement_uai].id).count

    # test regroupements
    get("/alimentation/bilan/#{types[1]}/#{@etablissement_uai}").status.should == 200 
    bilan_regroupement = JSON.parse(last_response.body)
    bilan_regroupement[0]["CLASSES"].count.should == Regroupement.where(:type_regroupement_id => 'CLS',
      :etablissement_id => Etablissement[:code_uai => @etablissement_uai].id).count
    bilan_regroupement[1]["GROUPES"].count.should == Regroupement.where(:type_regroupement_id => 'GRP',
      :etablissement_id => Etablissement[:code_uai => @etablissement_uai].id).count

    #test 
    
  end  
end
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
    #@etablissement_uai = "0690002C"
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


  it "synchronize mef educ nat" , :broken => true do
    # check response status
    get("/alimentation/sync_mef").status.should == 200
    
    # check that the number of inserted  records is correct
    JSON.parse(last_response.body)["niveaux"].should == Niveau.count
    rand = rand(Niveau.count)
    
    # check that  data is correct
    # take a random record and then chek the existence in the data base
    get("/alimentation/data/mef/00000").status.should == 200
    data = JSON.parse(last_response.body)["data"] 
    random_record = data[rand]
    found = Niveau.where[:ent_mef_jointure => random_record["ENTMefJointure"]]
    found.should_not == nil
    found[:mef_libelle].should == random_record["ENTLibelleMef"]
   
  end

  it "synchronize matieres" , :broken => true do
    get("/alimentation/sync_mat").status.should == 200  
    JSON.parse(last_response.body)["matieres"].should == MatiereEnseignee.count
    rand = rand(MatiereEnseignee.count)
    
    # check that  data is correct
    # take a random record and then chek the existence in the data base
    get("/alimentation/data/matieres/00000").status.should == 200
    data = JSON.parse(last_response.body)["data"] 
    random_record = data[rand]
    found = MatiereEnseignee.where[:id => random_record["ENTMatJointure"]]
    found.should_not == nil
    found[:libelle_long].should == random_record["ENTLibelleMatiere"]

  end

  it "synchronize the fonctions" , :broken => true do #, :broken => true do
    # check response is correct
    get("/alimentation/sync_fonc").status.should == 200
    JSON.parse(last_response.body)["fonctions"].should == Fonction.count
    rand = rand(Fonction.count)

    # check data is correct 
    # take a random record and then chek the existence in the data base
    #{"code_men":"AUCUNE","libelle":"ADMINISTRATION","description":"AUCUNE"}
    get("/alimentation/data/fonctions/00000").status.should == 200
    data = JSON.parse(last_response.body)["data"] 
    random_record = data[rand]
    found = Fonction.where[:code_men => random_record["code_men"], :libelle => random_record["libelle"]]
    found.should_not == nil
    found[:description].should == random_record["description"]
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
    #Example Response
    #response_body = {"errors":[],"etablissement":{"uai":"0690078K","sync_time":0.004647719,"errors":[]},
    #"classes":{"count":18,"sync_time":0.031558624,"errors":[]},
    #"groupes":{"count":40,"sync_time":0.069475176,"errors":[]},
    #"eleves":{"count":456,"sync_time":2.297566469,"errors":[]},
    #"pers_educ_nat":{"count":79,"sync_time":0.520451235,"errors":[]},
    #"parent":{"count":775,"sync_time":6.754085487,"errors":[]},
    #"pers_rel_eleve":{"count":908,"sync_time":1.856864411,"errors":["person with id_jointure_aaf: 1355149 does not exist", ..],
    #"rattachement_eleves":{"count":1013,"sync_time":3.498605378,"errors":[]},
    #"rattachement_profs":{"count":217,"sync_time":0.914587528,"errors":[]},
    #"detachements":{"count":0,"sync_time":0.000122432,"errors":[]},
    #"fonction_pen":{"count":76,"sync_time":0.318768332,"errors":[]}}
    response = JSON.parse(last_response.body)
     
    types = ["bilan_comptes", "bilan_regroupements"]
    get("/alimentation/bilan/#{types[0]}/#{@etablissement_uai}").status.should == 200 
    bilan_comptes = JSON.parse(last_response.body)
    
    etablissement_id = Etablissement[:code_uai => @etablissement_uai].id
    # compare to bilan received from the server
    # bilan comptes 
    bilan_comptes[0]["ELEVE"][1]["nb"].to_i.should == ProfilUser.where(:profil_id => 'ELV', 
      :etablissement_id => Etablissement[:code_uai => @etablissement_uai].id).count
    bilan_comptes[1]["PARENT"][2]["nb"].to_i.should ==  ProfilUser.where(:profil_id => 'TUT', 
      :etablissement_id => Etablissement[:code_uai => @etablissement_uai].id).count
    # i can not test the number of profs
    bilan_comptes[2]["PERSEDUCNAT"][1]["nb"].to_i.should >= ProfilUser.where(:profil_id => 'ENS', 
      :etablissement_id => Etablissement[:code_uai => @etablissement_uai].id).count

    # test regroupements
    get("/alimentation/bilan/#{types[1]}/#{@etablissement_uai}").status.should == 200 
    bilan_regroupement = JSON.parse(last_response.body)
    bilan_regroupement[0]["CLASSES"].count.should == Regroupement.where(:type_regroupement_id => 'CLS',
      :etablissement_id => Etablissement[:code_uai => @etablissement_uai].id).count
    bilan_regroupement[1]["GROUPES"].count.should == Regroupement.where(:type_regroupement_id => 'GRP',
      :etablissement_id => Etablissement[:code_uai => @etablissement_uai].id).count

    # check that processing results have no errors and coherent with the database 
    response["errors"].count.should == 0 
    response["etablissement"]["errors"].count.should == 0
    response["classes"]["errors"].count.should == 0
    response["groupes"]["errors"].count.should == 0 
    response["eleves"]["errors"].count.should == 0
    response["parent"]["errors"].count.should == 0
    response["pers_educ_nat"]["errors"].count.should == 0
    # actuellement  il y des erreurs dans le parsing des pers_rel_eleve
    # il ya des person qui n'existe pas
    
   
    response["rattachement_eleves"]["errors"].count.should == 0
    #inserted records equals parsed records
    response["rattachement_eleves"]["count"].should ==  EleveDansRegroupement.where(:regroupement => 
      Regroupement.where(:etablissement_id => etablissement_id)).count

    #response["pers_rel_eleve"]["errors"].count.should == 0
    #response["pers_rel_eleve"]["count"].should == RelationEleve.where(:eleve_id  => 
      #ProfilUser.where(:profil_id => "ELV", :etablissement_id => etablissement_id).select(:user_id)).count

    response["rattachement_profs"]["errors"].count.should == 0
    response["rattachement_profs"]["count"].should == EnseigneDansRegroupement.where(:regroupement => 
      Regroupement.where(:etablissement_id => etablissement_id)).count

    #{"data":[{"profil":"ELEVE","id_jointure_aaf":"2417366"},{"profil":"ELEVE","id_jointure_aaf":"2426302"},
    #{"profil":"ELEVE","id_jointure_aaf":"2426964"},{"profil":"ELEVE","id_jointure_aaf":"2652358"},{"profil":"ELEVE","id_jointure_aaf":"2652360"},
    #{"profil":"PARENT","id_jointure_aaf":"2457365"},{"profil":"PARENT","id_jointure_aaf":"2461219"},
    #{"profil":"PARENT","id_jointure_aaf":"2461223"},{"profil":"PARENT","id_jointure_aaf":"2499510"},
    #{"profil":"PARENT","id_jointure_aaf":"2499532"},{"profil":"PARENT","id_jointure_aaf":"2504071"},
    #{"profil":"PARENT","id_jointure_aaf":"2652410"},{"profil":"PARENT","id_jointure_aaf":"2652412"},
    #{"profil":"PERSEDUCNAT","id_jointure_aaf":"2651724"},{"profil":"PERSEDUCNAT","id_jointure_aaf":"2652261"},
    #{"profil":"PERSEDUCNAT","id_jointure_aaf":"2652340"},{"profil":"PERSEDUCNAT","id_jointure_aaf":"2668669"},
    #{"profil":"PERSEDUCNAT","id_jointure_aaf":"2670744"}],"count":18}
    # testing dettachement depends on the type of Profil
    response["detachements"]["errors"].count.should == 0
    get("/alimentation/data/detachements/#{@etablissement_uai}").status.should == 200
    count = JSON.parse(last_response.body)["count"]
    response["detachements"]["count"].should == count
    # this test is not sufficient, we must be sure that profils has been deleted
    

    response["fonction_pen"]["errors"].count.should == 0

    #  check that processing results are coherent           
    #test 
  end  
end
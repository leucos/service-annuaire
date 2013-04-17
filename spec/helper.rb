#coding: utf-8
require 'rspec'
require 'rack/test'
require 'rubygems'

require_relative '../app'


# On lance tous les tests dans une transaction ce qui fait
# que l'on a pas a supprimer quoique ce soit, sequel le fait pour nous :)

RSpec.configure do |c|
  c.around(:each) do |example|
    Sequel.transaction([DB, ORACLE], :rollback=>:always){example.run}
    #Sequel.transaction([DB, ORACLE]){example.run}
  end
  c.filter_run_excluding :broken => true
end


Mail.defaults do
  delivery_method :test
end

def get_etablissement_list 
  begin
    get("/alimentation/etablissements")
    json_response= JSON.parse(last_response.body)
    array_of_etablissements = json_response["data"]
    array_of_etablissements.map{|etablissement| etablissement["code_uai"]}
  rescue => e 
    []
  end    
end

def mock_list  
  # list of etablissement
  # TODO: Get the list dynamically 
  ["0011241U", "0019999N", "0699999U", "0421943J", "0429999R", "0690015S", "0690133V", "0693307V", "0690016T", 
    "0690036P", "0690002C", "0690005F", "0692699J", "0692578C", "0693365H", "0692693C", "0693331W", "0692521R", 
    "0693834T", "0694007F", "0693975W", "0691484N", "0691497C", "0691498D", "0691666L", "0691669P", "0691670R", 
    "0691727C", "0691824H", "0690040U", "0690053H", "0690060R", "0690070B", "0690075G", "0690076H", "0690078K", 
    "0690097F", "0691479H", "0691645N", "0690131T", "0690280E", "0691478G", "0690614T", "0691481K", "0690001B", 
    "0692937T", "0692696F", "0692163B", "0692155T", "0692164C", "0692334M", "0692335N", "0692339T", "0692343X", 
    "0692346A", "0692419E", "0692420F", "0693890D", "0692520P", "0692448L", "0694151M", "0692703N", "0692865P", 
    "0692933N", "0690007H", "0690022Z", "0690094C", "0690590S", "0691483M", "0691663H", "0691664J", "0691675W", 
    "0691673U", "0691728D", "0692160Y", "0692337R", "0692338S", "0692340U", "0692422H", "0692704P", "0692925E", 
    "0693046L", "0693287Y", "0693479G"
  ]
  #["0692578C", "0693365H", "0692693C", "0690078K"]
end  

#----------------------------------------------------------#
# create and delete test users functions
def create_test_user(login = "test")
  User.create(:login => login, :password => 'test', :nom => 'test', :prenom => 'test')
end

def new_test_user(login = "test")
  User.new(:login => login, :password => 'test', :nom => 'test', :prenom => 'test')
end

def delete_test_users()
  User.filter(:nom => "test", :prenom => 'test').destroy()
  User.filter(:login => "test").destroy()
end

def delete_test_user(login = "test")
  User.filter(:login => login).destroy()
end
#-----------------------------------------------------------#
# create and delete test etablissement functions
def create_test_etablissement(nom = "test_etablissement")
  Etablissement.create(:nom => nom, :type_etablissement => TypeEtablissement.first)
end

def delete_test_etablissements
  Etablissement.filter(:nom => "test_etablissement").destroy()
end

def create_class_in_etablissement(etablissement_id)
  r = Regroupement.create(:libelle => "test class", :type_regroupement_id => "CLS", 
      :etablissement_id => etablissement_id, :code_mef_aaf => "00010001310")
end 
#------------------------------------------------------------#

def create_test_application_with_param
  a = Application.create(:id => "test")
  ParamApplication.create(:code => "test_pref", :preference => true, 
    :application => a, :type_param_id => TYP_PARAM_NUMBER)
  ParamApplication.create(:code => "test_param", :preference => false, 
    :application => a, :type_param_id => TYP_PARAM_NUMBER)
  ParamApplication.create(:code => "test_pref2", :preference => true, 
    :application => a, :type_param_id => TYP_PARAM_NUMBER)
  return a
end
# input params = {"param_name" => true/false } true/false signifies preference or parameter
def create_test_application_with_params(app_id, parameters)
  a = Application.create(:id => app_id)
  parameters.each do |key, value|
    ParamApplication.create(:code => key, :preference => value, 
      :application => a, :type_param_id => TYP_PARAM_NUMBER)
  end
  return a  
end

def delete_application(app_id)
  Application.filter(:id => app_id).destroy()
end 

def delete_test_application
  Application.filter(:id => "test").destroy()
end
#------------------------------------------------------------#

ROL_TEST = "TEST"
def create_test_role(application_id)
  # example test role for etablissement admin
  r = Role.find_or_create(:id => ROL_TEST, :application_id => application_id)
  r.add_activite(SRV_USER, ACT_CREATE, "belongs_to")
  r.add_activite(SRV_ETAB, ACT_UPDATE, "self")
  r.add_activite(SRV_ETAB, ACT_READ, "self")
  r.add_activite(SRV_CLASSE, ACT_DELETE, "belongs_to")
  return r
end
def create_admin_etab_test_role(application_id)
  # example test role for etablissement admin
  r = Role.find_or_create(:id => ROL_TEST, :application_id => application_id)
  r.add_activite(SRV_USER, ACT_READ, "belongs_to")
  r.add_activite(SRV_USER, ACT_UPDATE, "belongs_to")
  r.add_activite(SRV_USER, ACT_CREATE, "belongs_to")
  r.add_activite(SRV_USER, ACT_DELETE, "belongs_to")
  r.add_activite(SRV_ETAB, ACT_UPDATE, "self")
  r.add_activite(SRV_ETAB, ACT_READ, "self")
  r.add_activite(SRV_CLASSE, ACT_READ, "belongs_to")
  r.add_activite(SRV_CLASSE, ACT_DELETE, "belongs_to")
  r.add_activite(SRV_CLASSE, ACT_CREATE, "belongs_to")
  return r
end

def create_admin_laclasse_role(application_id)
  r = Role.find_or_create(:id => "admin", :application_id => application_id)
  r.add_activite(SRV_USER, ACT_READ, "all")
  r.add_activite(SRV_USER, ACT_UPDATE, "all")
  r.add_activite(SRV_USER, ACT_CREATE, "all")
  r.add_activite(SRV_USER, ACT_DELETE, "all")
  r.add_activite(SRV_ETAB, ACT_UPDATE, "all")
  r.add_activite(SRV_ETAB, ACT_READ, "all")
  r.add_activite(SRV_CLASSE, ACT_READ, "all")
  r.add_activite(SRV_CLASSE, ACT_DELETE, "all")
  r.add_activite(SRV_CLASSE, ACT_CREATE, "all")
  r
end  

def create_test_role_with_id(role_id)
  r = Role.create(:id => role_id, :service_id => SRV_ETAB)
  return r
end

def delete_test_role_with_id(role_id)
   Role[:id => role_id].destroy() if Role[:id => role_id]
end 


def delete_test_role
  Role[ROL_TEST].destroy() if Role[ROL_TEST]
end

def create_user_with_role(role_id, ressource = nil)
  u = create_test_user("test_admin")
  # On créer un role de test sur l'ensemble de LACLASSE.com si la ressource
  # n'est pas précisée
  ressource = Ressource[:service_id => SRV_LACLASSE] if ressource.nil?
  RoleUser.create(:user_id => u.id, 
    :ressource_id => ressource.id, :ressource_service_id => ressource.service_id,
    :role_id => role_id)
  return u
end

def create_test_eleve_with_parents()
  u = create_test_user("test1")
  u.id_sconet = 123456
  u.save()
  p1 = create_test_user()
  p1.prenom = "roger"
  p1.save()
  p2 = create_test_user("test2")

  # Il faut au moins un etablissement
  e = Etablissement.first
  u.add_profil({:user => u, :etablissement => e, :profil_id => PRF_ELV})
  p1.add_profil({:user => p1, :etablissement => e, :profil_id => PRF_PAR})
  p2.add_profil({:user => p2, :etablissement => e, :profil_id => PRF_PAR})

  # "vrai" parent
  u.add_parent(p1)
  # Representant legal
  u.add_parent(p2, TYP_REL_RLGL)
  return u
end

def delete_test_eleve_with_parents
  User.filter(:login => "test1").destroy
  User.filter(:login => "test2").destroy
end 

def create_test_user_in_etab(etb_id, login, profil_id = "ELV")
  u = create_test_user(login)
  # On assigne manuellement la ressource utilisateur à cet établissement
  #r = Ressource[:id => u.id, :service_id => SRV_USER]
  #r.parent_id = etb_id
  #r.parent_service_id = SRV_ETAB
  #r.save()
  ProfilUser.create(:user_id => u.id, :etablissement_id => etb_id, :profil_id => profil_id)
  u
end

def create_test_ressources_tree
  e = Etablissement.create(:nom => "test", :type_etablissement => TypeEtablissement.first)
  create_test_user_in_etab(e.id, "test")
  create_test_user_in_etab(e.id, "test2")
  return Ressource[:id => e.id, :service_id => SRV_ETAB]
end

def delete_test_ressources_tree
  delete_test_users()
  Etablissement.filter(:nom => "test").destroy()
end


# HELPER SPECIFIC A L ALIMENTATION AUTO
FILE_DIR = "spec/fixtures"
TMP_DIR = "tmp"

FILE_LIST = [
  File.join(FILE_DIR, "complet", "ENT_0691670R_Complet_20120504_PersEducNat_0000.xml"),
  File.join(FILE_DIR, "complet", "ENT_0691670R_Complet_20120504_Eleve_0000.xml"),
  File.join(FILE_DIR, "complet", "ENT_0691670R_Complet_20120504_PersRelEleve_0000.xml"),
  File.join(FILE_DIR, "complet", "ENT_0691670R_Complet_20120504_EtabEducNat_0000.xml")
]

# Contient :
# - renommage classe 4E3 en 4E12
# - renommage du professeur 880465
# - suppression de l'élève 748220 et de l'élève 768826
# - changement de mère pour l'élève 1293451
# - changement d'adresse et numéro de téléphone du parent 386679
# - enlève prof 331 de la 4E3
DELTA_1_LIST = [
  File.join(FILE_DIR, "delta_1", "ENT_0691670R_Delta_20120511_PersEducNat_0000.xml"),
  File.join(FILE_DIR, "delta_1", "ENT_0691670R_Delta_20120511_Eleve_0000.xml"),
  File.join(FILE_DIR, "delta_1", "ENT_0691670R_Delta_20120511_PersRelEleve_0000.xml"),
  File.join(FILE_DIR, "delta_1", "ENT_0691670R_Delta_20120511_EtabEducNat_0000.xml")
]

# Contient :
# - Renommage de l'elève 755478 (Loli=>Lola)
# - Change de classe l'élève 1293456
DELTA_2_LIST = [
  File.join(FILE_DIR, "delta_2", "ENT_0691670R_Delta_20120512_PersEducNat_0000.xml"),
  File.join(FILE_DIR, "delta_2", "ENT_0691670R_Delta_20120512_Eleve_0000.xml"),
  File.join(FILE_DIR, "delta_2", "ENT_0691670R_Delta_20120512_PersRelEleve_0000.xml"),
  File.join(FILE_DIR, "delta_2", "ENT_0691670R_Delta_20120512_EtabEducNat_0000.xml")
]

#Ne contient normalement aucunes modifs
COMPLET_2_LIST = [
  File.join(FILE_DIR, "complet_2", "ENT_0691670R_Complet_20120516_PersEducNat_0000.xml"),
  File.join(FILE_DIR, "complet_2", "ENT_0691670R_Complet_20120516_Eleve_0000.xml"),
  File.join(FILE_DIR, "complet_2", "ENT_0691670R_Complet_20120516_PersRelEleve_0000.xml"),
  File.join(FILE_DIR, "complet_2", "ENT_0691670R_Complet_20120516_EtabEducNat_0000.xml")
]

ETB_UAI = "0691670R"

NB_ELV = 51
NB_PAR = 96
NB_MEN = 48
NB_CONT = 31
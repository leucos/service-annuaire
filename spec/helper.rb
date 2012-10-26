#coding: utf-8
require 'ramaze'
require 'ramaze/spec/bacon'
require 'json'

require_relative '../app'

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
  u.add_profil({:user => u, :etablissement => e, :profil_id => PRF_ELV, :actif => true})
  p1.add_profil({:user => p1, :etablissement => e, :profil_id => PRF_PAR, :actif => true})
  p2.add_profil({:user => p2, :etablissement => e, :profil_id => PRF_PAR, :actif => true})

  # "vrai" parent
  u.add_parent(p1)
  # Representant legal
  u.add_parent(p2, TYP_REL_RLGL)
  return u
end

def create_test_user_in_etab(etb_id, login)
  u = create_test_user(login)
  # On assigne manuellement la ressource utilisateur à cet établissement
  r = Ressource[:id => u.id, :service_id => SRV_USER]
  r.parent_id = etb_id
  r.parent_service_id = SRV_ETAB
  r.save()
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
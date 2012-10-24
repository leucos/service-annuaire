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
  User.filter(:nom => "test", :prenom => 'test').delete()
  User.filter(:login => "test").delete()
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
  u.add_profil({:user => u, :etablissement => e, :profil_id => 'ELV', :actif => true})
  p1.add_profil({:user => p1, :etablissement => e, :profil_id => 'PAR', :actif => true})
  p2.add_profil({:user => p2, :etablissement => e, :profil_id => 'PAR', :actif => true})

  #todo : faire des fonctions dans User pour faire ça...
  # "vrai" parent
  DB[:relation_eleve].insert(:user_id => p1.id, :eleve_id => u.id, :type_relation_eleve_id => "PAR")
  # Representant legal
  DB[:relation_eleve].insert(:user_id => p2.id, :eleve_id => u.id, :type_relation_eleve_id => "RLGL")
  return u
end

def delete_test_eleve_with_parents()
  u = User[:login => "test"]
  RelationEleve.filter(:eleve_id => u.id).delete() if u
  ProfilUser.filter(:user => User.filter(:nom => "test", :prenom => "test")).delete()
  ProfilUser.filter(:user => User.filter(:login => "test")).delete()
  delete_test_users()
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
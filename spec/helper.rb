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

def create_test_eleve(login = "eleve")

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
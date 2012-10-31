#coding: utf-8
#
# model for 'etablissement' table
# generated 2012-05-30 11:31:02 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | char(8)             | false    | PRI      |            | 
# nom                           | varchar(255)        | true     |          |            | 
# siren                         | varchar(45)         | true     |          |            | 
# adresse                       | varchar(255)        | true     |          |            | 
# code_postal                   | char(6)             | true     |          |            | 
# ville                         | varchar(255)        | true     |          |            | 
# telephone                     | varchar(32)         | true     |          |            | 
# fax                           | varchar(32)         | true     |          |            | 
# type_etablissement_id         | int(11)             | false    | MUL      |            | 
# longitude                     | float               | true     |          |            | 
# latitude                      | float               | true     |          |            | 
# date_last_maj_aaf             | date                | true     |          |            | 
# nom_passerelle                | varchar(255)        | true     |          |            | 
# ip_pub_passerelle             | varchar(45)         | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Etablissement < Sequel::Model(:etablissement)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer
  plugin :ressource_link, :service_id => SRV_ETAB

  # Referential integrity
  one_to_many :application_etablissement
  one_to_many :profil_user
  one_to_many :regroupement
  many_to_one :type_etablissement

  # Not nullable cols
  def validate
    super
    validates_presence [:type_etablissement_id]
  end

  # Check si l'id passé en paramètre correspond bien aux critères d'identifiant ENT
  def self.is_valid_id(id)
    id.class == String and id.length == 8 and id[7] =~ /[a-zA-Z]/
  end
  
  # les classes dans l'etablissement 
  def classes
    Regroupement.filter(:etablissement => self, :type_regroupement_id => 'CLS').all
  end

  # les groupes d'eleve  dans l'etablissement
  def groupes_eleves
    Regroupement.filter(:etablissement => self, :type_regroupement_id => 'GRP').all
  end

  # les groupes libre dans l'etablissement 
  def groupes_libres
    Regroupement.filter(:etablissement => self, :type_regroupement_id => 'LBR').all  
  end 

  # Liste de tous les membres d'un établissement qui font parti de l'éducation nationale
  def personnel
    # Seul les profil ayant un code ministeriel font parti de l'éducation nationale.
    # temp : peut-etre un peu léger, que faire des cuisiniers (sont-ils alimentés) par exemple ?
    User.filter(:profil_user => ProfilUser.
      filter(:etablissement => self, :profil => Profil.exclude(:code_men => nil))).all
  end

  def contacts
    User.filter(:profil_user => ProfilUser.filter(:etablissement => self, :profil_id => ["ADM", "DIR"])).all
  end 

  # retourn le type de l'Etablissement suivi par son nom
  def full_name
    typeetab = TypeEtablissement.select(:nom).where(:id => type_etablissement_id).first
    "#{typeetab.nom} #{nom}"


  end
end

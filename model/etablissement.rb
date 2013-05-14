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
  plugin :fuzzy_search

  # Referential integrity
  one_to_many :application_etablissement
  one_to_many :profil_user
  one_to_many :regroupement
  many_to_one :type_etablissement
  one_to_many :param_etablissement

  # id is received from the alimentation
  unrestrict_primary_key()
  # Not nullable cols
  def validate
    super
    validates_presence [:type_etablissement_id]
  end

  def before_destroy
    application_etablissement_dataset.destroy()
    profil_user_dataset.destroy()
    regroupement_dataset.destroy()
    param_etablissement_dataset.destroy()
    #profil_user_has_fonction_dataset.destroy()
    super
  end

  # Check si l'id passé en paramètre correspond bien aux critères d'identifiant ENT
  def self.is_valid_id(id)
    id.class == String and id.length == 8 and id[7] =~ /[a-zA-Z]/
  end

  def add_classe(hash)
    hash[:type_regroupement_id] = 'CLS'
    add_regroupement(hash)
  end

  def add_groupe_eleve(hash)
    hash[:type_regroupement_id] = 'GRP'
    add_regroupement(hash)
  end

  def add_groupe_libre(hash)
    hash[:type_regroupement_id] = 'LBR'
    add_regroupement(hash)
  end

  def add_regroupement(regroupement_hash)
    regroupement_hash[:etablissement_id] = self.id if regroupement_hash[:etablissement_id].nil?
    Regroupement.create(regroupement_hash)
  end

  def add_application(application_id)
    ApplicationEtablissement.create(:application_id => application_id, :etablissement => self)
  end

  def remove_application(application_id)
    ApplicationEtablissement.filter(:application_id => application_id, :etablissement => self).destroy()
  end
  
  # les classes dans l'etablissement 
  def classes
    #Regroupement.where(:etablissement => self, :type_regroupement_id => "CLS").to_hash
    #DB[:regroupement].where(:etablissement => self, :type_regroupement_id => "CLS").to_hash
    regroupement_dataset.where(:type_regroupement_id => "CLS").all
  end

  # les groupes d'eleve  dans l'etablissement
  def groupes_eleves
    Regroupement.filter(:etablissement => self, :type_regroupement_id => TYP_REG_GRP).all
  end

  # les groupes libre dans l'etablissement 
  def groupes_libres
    Regroupement.filter(:etablissement => self, :type_regroupement_id => TYP_REG_LBR).all  
  end 

  # Liste de tous les membres d'un établissement qui font parti de l'éducation nationale
  def personnel
    # Seul les profil ayant un code ministeriel font parti de l'éducation nationale.
    # temp : peut-etre un peu léger, que faire des cuisiniers (sont-ils alimentés) par exemple ?
    User.filter(:profil_user => ProfilUser.filter(:etablissement => self, :profil_id => Profil.exclude(:id => ["ELV", "TUT"]).select(:id))).all
  end

  def contacts
    User.filter(:profil_user => ProfilUser.filter(:etablissement => self, :profil_id => ["ADM", "DIR"])).all
  end 

  # retourn le type de l'Etablissement suivi par son nom
  def full_name
    "#{type_etablissement.nom} #{nom}"
  end

  # temp : code trop similaire à User, mettre ça dans un librairie
  # Set la valeur d'une préférence sur un établissement
  # @param valeur, si nil alors détruit la préférence
  def set_preference(preference_id, valeur)
    param = ParamEtablissement[:etablissement => self, :param_application_id => preference_id]
    if param
      if valeur
        param.update(:valeur => valeur)
      else
        param.destroy()
      end
    elsif valeur
      ParamEtablissement.create(:etablissement => self, :param_application_id => preference_id, :valeur => valeur)
    end
  end

  # Renvois les preferences d'un établissement sur une application
  def preferences(application_id, code = "all")
    preferences = DB[:param_application].
      join_table(:left, :param_etablissement, {:param_application_id => :id, :etablissement_id => self.id}).
      filter(:application_id => application_id, :preference => false)
    if code != "all"
      preferences = preferences.filter(:code => code)
    end 
    preferences.select(:id, :valeur_defaut, :valeur, :libelle, :description, :autres_valeurs, :type_param_id).
      all   
  end
end

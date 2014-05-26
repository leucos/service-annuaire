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
    ds1 = DB.fetch("SELECT `regroupement_id`, count(user_id) AS `profs` FROM `enseigne_dans_regroupement` GROUP BY `regroupement_id`")
    ds2 = DB.fetch("SELECT `regroupement_id`, count(user_id) AS `eleves` FROM `eleve_dans_regroupement` GROUP BY `regroupement_id`") 
    regroupement_dataset.where(:type_regroupement_id => "CLS").left_join(ds1, :regroupement_id => :id)
    .left_join(ds2, :regroupement_id => :regroupement__id)
    .left_join(:niveau, :ent_mef_jointure => :regroupement__code_mef_aaf)
    .naked.all
  end

  # les groupes d'eleve  dans l'etablissement
  def groupes_eleves
    ds1 = DB.fetch("SELECT `regroupement_id`, count(user_id) AS `profs` FROM `enseigne_dans_regroupement` GROUP BY `regroupement_id`")
    ds2 = DB.fetch("SELECT `regroupement_id`, count(user_id) AS `eleves` FROM `eleve_dans_regroupement` GROUP BY `regroupement_id`") 
    regroupement_dataset.where(:type_regroupement_id => "GRP").left_join(ds1, :regroupement_id => :id).left_join(ds2, :regroupement_id => :regroupement__id).naked.all
  end

  # les groupes libre dans l'etablissement 
  def groupes_libres
    #ds1 = DB.fetch("SELECT `regroupement_id`, count(user_id) AS `profs` FROM `enseigne_dans_regroupement` GROUP BY `regroupement_id`")
    #ds2 = DB.fetch("SELECT `regroupement_id`, count(user_id) AS `eleves` FROM `eleve_dans_regroupement` GROUP BY `regroupement_id`") 
    #regroupement_dataset.where(:type_regroupement_id => "LBR").left_join(ds1, :regroupement_id => :id).left_join(ds2, :regroupement_id => :regroupement__id).naked.all
    #RegroupementLibre.naked.all
    ds1 = MembreRegroupementLibre.group_and_count(:regroupement_libre_id) 
    ds2 = RegroupementLibre.join(:user, :user__id => :created_by)
    #ds2.naked.all
    #.select(:regroupement_libre__id, :regroupement_libre__libelle, 
      #:regroupement_libre__created_at, :user__nom, :user__prenom, :user__id_ent, ds1__count)

    ds2.left_join(ds1, :regroupement_libre_id => :regroupement_libre__id).select(:regroupement_libre__id,
      :regroupement_libre__created_at, :user__nom, :user__prenom, :user__id_ent,:libelle,:count___membres).naked.all
  end 

  # Liste de tous les membres d'un établissement qui font parti de l'éducation nationale
  def personnel
    # Seul les profil ayant un code ministeriel font parti de l'éducation nationale.
    # temp : peut-etre un peu léger, que faire des cuisiniers (sont-ils alimentés) par exemple ?
    User.join(:profil_user, :user_id => :id)
    .join(:profil_national, :profil_national__id => :profil_id)
    .join(:profil_user_fonction, :profil_user_fonction__profil_id => :profil_user__profil_id, :profil_user_fonction__user_id => :profil_user__user_id)
    .join(:fonction, :fonction__id => :profil_user_fonction__fonction_id)
    .filter(:profil_user__etablissement_id => self.id, :profil_user__profil_id => Profil.exclude(:id => ["ELV", "TUT"]).select(:id))
    .select(:user__id, :id_ent, :nom, :prenom, :profil_user__profil_id, :profil_national__description, :profil_user__etablissement_id, :code_national, 
      :fonction__libelle, :fonction__description)
    .distinct.naked.all
  end

  def matieres
    self.regroupement_dataset
    .join(:enseigne_dans_regroupement, :regroupement_id => :id)
    .join(:matiere_enseignee, :matiere_enseignee__id => :matiere_enseignee_id)
    .select(:matiere_enseignee__id, :matiere_enseignee__libelle_long, :matiere_enseignee__libelle_court).distinct.naked.all
  end


  def add_matieres(matiere_id)

  end

  def contacts
    
    ds1 = User.join(:role_user, :user_id =>:user__id).filter(:role_id =>["ADM_ETB", "TECH"], :role_user__etablissement_id => self.id).join(:role, :id => :role_user__role_id)
    .select(:id_ent, :nom, :prenom, :libelle, :role_id)
    ds2 = User.join(:profil_user_fonction, :user_id => :user__id).join(:fonction, :fonction__id =>:fonction_id)
    .filter(:profil_id => ["ADM", "DIR"], :etablissement_id => self.id).select(:id_ent, :nom, :prenom, :description, :profil_id)
    ds2.union(ds1).naked.all
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
    preferences.select(:id, :code, :valeur_defaut, :valeur, :libelle, :description, :autres_valeurs, :type_param_id).
      all   
  end


  # all (eleves) dans l'etablissement 
  def eleves
    ProfilUser.join(:user, :id => :user_id).filter(:profil_id => "ELV", :etablissement_id => self.id)
    .select(:profil_id, :user_id, :etablissement_id, :id_sconet, :id_jointure_aaf, 
      :nom, :prenom, :id_ent).naked.all
  end

  def eleves_exclude(regroupement_id)
    if Regroupement[:id => regroupement_id, :etablissement_id => self.id]  
      ProfilUser.join(:user, :id => :user_id).filter(:profil_id => "ELV", :etablissement_id => self.id)
      .exclude(:id => EleveDansRegroupement.filter(:regroupement_id => regroupement_id).select(:user_id))
      .select(:profil_id, :user_id, :etablissement_id, :id_sconet, :id_jointure_aaf, 
        :nom, :prenom, :id_ent).naked.all
    else 
      []
    end 
  end

  def applications
    self.application_etablissement_dataset.join(:application, :id => :application_id).naked.all
  end

  def active_applications
    self.application_etablissement_dataset.join(:application, :id => :application_id).where(:application_etablissement__active => true).naked.all
  end

  # (Eleves) that do not belong to any Class
  def eleves_libres
    ProfilUser.join(:user, :id => :user_id).filter(:profil_id => "ELV", :etablissement_id => self.id).select(:id, :id_ent)
    .exclude(:id => EleveDansRegroupement.join(:regroupement, :id => :regroupement_id).filter(:type_regroupement_id => "CLS", :etablissement_id=> self.id).select(:user_id))
    .select(:profil_id, :user_id, :etablissement_id, :id_sconet, :id_jointure_aaf, 
      :nom, :prenom, :id_ent).naked.all
  end  

  # Tous les enseignants dans l'etablissement 
  def enseignants
    ProfilUser.join(:user, :id => :user_id).filter(:profil_id => "ENS", :etablissement_id => self.id)
    .select(:profil_id, :user_id, :etablissement_id, :id_sconet, :id_jointure_aaf, 
      :nom, :prenom, :id_ent).naked.all
  end

  # Tous les Parents
  def parents
    ProfilUser.join(:user, :id => :user_id).filter(:profil_id => "TUT", :Etablissement_id => self.id)
      .select(:profil_id, :user_id, :etablissement_id, :id_sconet, :id_jointure_aaf, 
      :nom, :prenom, :id_ent).naked.all
  end

  # dettacher l'utilisateur de l'etablissement.
  def remove_user(user_id)
    ProfilUser.join(:user, :id => :user_id).filter(:user_id => user_id, :etablissement_id => self.id).destroy
  end

  # Merge 2 accounts in one account
  def merge_accounts(user1, user2, newUser)
    DB.transaction do  
      user = new User() 
      user.nom = newUser.nom
      user.prenom = newUser.prenom
      user.login = newUser.login
      user.save
    end 
  end
end

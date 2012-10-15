#coding: utf-8
#
# model for 'user' table
# generated 2012-04-19 17:45:32 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | char(8)             | false    | PRI      |            | 
# id_sconet                     | int(11)             | true     | UNI      |            | 
# id_jointure_aaf               | int(11)             | true     | UNI      |            | 
# login                         | varchar(45)         | false    |          |            | 
# password                      | char(32)            | true     |          |            | 
# nom                           | varchar(45)         | false    |          |            | 
# prenom                        | varchar(45)         | false    |          |            | 
# sexe                          | varchar(1)          | true     |          |            | 
# question_secrete              | varchar(512)        | true     |          |            | 
# reponse_question_secrete      | char(32)            | true     |          |            | 
# date_naissance                | date                | true     |          |            | 
# adresse                       | varchar(255)        | true     |          |            | 
# code_postal                   | char(6)             | true     |          |            | 
# ville                         | varchar(255)        | true     |          |            | 
# date_creation                 | date                | false    |          |            | 
# date_debut_activation         | date                | true     |          |            | 
# date_fin_activation           | date                | true     |          |            | 
# date_derniere_connexion       | date                | true     |          |            | 
# bloque                        | tinyint(1)          | false    |          | 0          | 
# date_last_maj_aaf             | date                | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class User < Sequel::Model(:user)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  one_to_many :enseigne_regroupement
  one_to_many :membre_regroupement
  one_to_many :profil_user
  one_to_many :telephone
  one_to_many :email
  # Check si l'id passé en paramètre correspond bien aux critères d'identifiant ENT
  def self.is_valid_id?(id)
    !!(id.class == String and id.length == 8 and id[0] == 'V' and id[3] == '6' and id[1..2] =~ /[a-zA-Z]{2}/ and id[4..7] =~ /\d{4}/)
  end

  def self.is_login_available(login)
    User[:login => login].nil?
  end

  def self.find_available_login(prenom, nom)
    #On lui créer un login/mot de passe par défaut de type 1ere lettre prenom + nom
    login = "#{prenom.strip[0].downcase}#{nom.gsub(/\s+/, "").downcase}"
    #On fait ici de la transliteration (joli hein :) pour éviter d'avoir des accents dans les logins
    login = I18n.transliterate(login)
    #Si homonymes, on utilise des numéros à la fin
    #todo prendre la deuxième lettre du prenom pour éviter les numéros ?
    login_number = 1
    final_login = login
    while !is_login_available(final_login)
      final_login = "#{login}#{login_number}"
      login_number += 1
    end

    return final_login
  end

  # Très important : Hook qui génère l'id unique du user avant de l'inserer dans la BDD
  def before_create
    self.id = UidGenerator::getNextUid()
    self.date_creation ||= Time.now
    super
  end

  # Not nullable cols
  def validate
    super
    validates_presence [:login, :nom, :prenom]
    validates_unique :login
    validates_unique :id_jointure_aaf if id_jointure_aaf
    validates_unique :id_sconet if id_sconet
    # Doit commencer par une lettre et ne pas comporter d'espace
    validates_format /^[a-z]\S*$/i, :login
    # Ne doit comporter que 5 chiffres
    validates_format /^\d{5}$/, :code_postal if code_postal
    # Le sexe est soit F  ou M
    validates_format /^[FM]$/, :sexe if sexe
  end

  def self.authenticate(creds)
    User[:login => creds[:user]]
  end

  def password
    BCrypt::Password.new(super)
  end

  # Utilise l'algorithme BCrypt pour haser le mot de passe
  def password= (pass)
    super(BCrypt::Password.create(pass))
  end

  def profil_actif
    profil_user.select{|p| p.actif}.first
  end

  #Trouve le rôle applicatif du profil courant pour l'application passé en paramètre
  #Ce rôle peut être définit par défaut ou surcharger pour l'utilisateur
  def role_application(application)
    user_profil = profil_actif
    if not user_profil.nil?
      #On cherche d'abord si l'utilisateur n'a pas un rôle spécifique 
      role_application = RoleUser.
          filter(:role=>Role.filter(:app => application), :profil_user => user_profil).first 
      if role_application.nil?
        #Si ce n'est pas le cas on prend le rôle lié à son profil
        role_application = RoleProfil.
          filter(:role => Role.filter(:app => application), :profil_id => user_profil.profil_id).first
      end
    else
       role_application = nil
    end

    #puts "role_application=#{role_application} application=#{application.id}, profil=#{user_profil.user_id}"
    return role_application.nil? ? nil : role_application.role
  end

  def activites(application)
    #On cherche a trouver les activités (action possible)
    #d'un utilisateur pour une application donnée sur son profil courant
    activite_code = []
    role = role_application(application)
    unless role.nil?
      activite_models = Activite.filter(:activite_role => ActiviteRole.filter(:role => role))
      activite_models.each do |a|
        activite_code.push(a.code.to_sym)
      end
    end
    return activite_code
  end

  #Change le profil de l'utilisateur
  def change_profil(new_profil, to_change = profil_actif)
    if profil_actif.profil != new_profil
      ProfilUser.find_or_create(:user => to_change.user, :actif => to_change.actif,
        :etablissement => to_change.etablissement, :profil => new_profil)

      #On supprime les role définit spécialement pour cette utilisateur
      RoleUser.filter(:profil_user => to_change).delete()
      to_change.destroy
      #IMPORTANT CAR LES ASSOCIATIONS SONT MISE EN CACHE
      refresh
    end
  end

  def add_profil(new_profil)
    new_profil = ProfilUser.find_or_create(new_profil)
    if new_profil.actif
      switch_profil(new_profil)
    end
  end

  def switch_profil(profil)
    current = profil_actif
    if profil != current
      current.actif = false
      current.save

      profil.actif = true
      profil.save

      #IMPORTANT CAR LES ASSOCIATIONS SONT MISE EN CACHE
      refresh
    end
  end

  def civilite
    sexe == 'F' ? 'Mme' : 'Mr'
  end

  # @return Nom complet de l'utilisateur formatté comme il se doit
  def full_name
    # @todo utiliser un camelize qu'on aura monkey patché a String
    "#{nom.capitalize} #{prenom.capitalize}"
  end

  #Classe dans laquelle est actuellement (profil actif) l'élève
  def classe
    regroupements('CLS').first
  end

  #Groupes auxquel l'élève est inscrit
  def groupes
    regroupements('GRP').all
  end

  def enseigne_classes
    enseigne_regroupements('CLS').all
  end

  def enseigne_groupes
    enseigne_regroupements('GRP').all
  end

  def matiere_enseigne
    MatiereEnseigne.
      filter(:enseigne_regroupement => EnseigneRegroupement.
        filter(:user => self, :regroupement => Regroupement.
          filter(:etablissement_id => profil_actif.etablissement_id))).all
  end

  def matiere_enseigne(groupe_id)
    MatiereEnseigne.
      filter(:enseigne_regroupement => EnseigneRegroupement.
        filter(:user => self, :regroupement_id  => groupe_id)).all
  end
  def etablissement
    return nil if profil_actif.nil?

    profil_actif.etablissement
  end

  def email_principal
    email = Email.filter(:user => self, :principal => true).first
    return email.nil? ? "" : email.adresse
  end

  def email_academique
    email = Email.filter(:user => self, :academique => true).first
    return email.nil? ? "" : email.adresse
  end


private
  def regroupements(type_id)
    Regroupement.filter(:type_regroupement_id => type_id,
      :etablissement_id => profil_actif.etablissement_id,
      :membre_regroupement => MembreRegroupement.filter(:user => self))
  end

  def enseigne_regroupements(type_id)
    Regroupement.filter(:type_regroupement_id => type_id,
      :etablissement_id => profil_actif.etablissement_id,
      :enseigne_regroupement => EnseigneRegroupement.filter(:user => self))
  end
end

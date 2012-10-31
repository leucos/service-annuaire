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
  plugin :ressource_link, :service_id => SRV_USER

  # Referential integrity
  one_to_many :enseigne_regroupement
  one_to_many :role_user
  one_to_many :profil_user
  one_to_many :telephone
  one_to_many :email
  # Liste de tous les élèves avec qui l'utilisateur est en relation
  many_to_many :relation_eleve, :left_key => :user_id, :right_key => :eleve_id, 
    :join_table => :relation_eleve, :class => self
  many_to_many :enfants, :left_key => :user_id, :right_key => :eleve_id, 
    :join_table => :relation_eleve, :class => self do |ds|
      ds.where(:type_relation_eleve_id => ["PAR", "RLGL"])
    end
  # Liste de tous les utilisateurs (adultes) avec qui l'élève est en relation
  many_to_many :relation_adulte, :left_key => :eleve_id, :right_key => :user_id, 
    :join_table => :relation_eleve, :class => self
  # Liste de tous les parents d'un élève
  many_to_many :parents, :left_key => :eleve_id, :right_key => :user_id, 
    :join_table => :relation_eleve, :class => self do |ds|
      ds.where(:type_relation_eleve_id => ["PAR", "RLGL"])
    end

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
    self.id = LastUid::get_next_uid()
    self.date_creation ||= Time.now
    super
  end

  def before_destroy
    #Supprime tous les email et les numéros de téléphone du User
    email_dataset.destroy()
    telephone_dataset.destroy()

    # Supprime aussi toutes les relation_eleve liées au User
    # La syntaxe pour les OR sql est pas évidente je trouve..
    RelationEleve.where(Sequel.expr(:user_id => self.id) | Sequel.expr(:eleve_id => self.id)).destroy()

    # On supprime tous les RoleUser liés à ce User
    role_user_dataset.destroy()
    
    # Et les enseignements
    enseigne_regroupement_dataset.destroy()

    # Enfin tous ses profils dans l'établissement
    profil_user_dataset.destroy()
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

  # Renvois toutes les relation_eleve dans lequel est impliqué l'utilisateur
  def relations
    RelationEleve.filter({:eleve_id => self.id, :user_id => self.id}.sql_or).all
  end

  def profil_actif
    role_user.select{|r| r.actif && r.ressource_service_id == SRV_ETAB}.first
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
  def set_profil(new_profil, to_change = profil_actif)
    if profil_actif.profil != new_profil
      # ProfilUser sert juste a afficher le profil administratif de l'utilisateur
      ProfilUser.find_or_create(:user => to_change.user, 
        :etablissement => to_change.etablissement, :profil => new_profil)

      RoleUser.find_or_create(:user => to_change.user, :actif => to_change.actif,
        :ressource_id => to_change.etablissement.id, :ressource_service_id => SRV_ETAB, 
        :role_id => new_profil.role_id)

      #On supprime les role définit spécialement pour cette utilisateur
      RoleUser.filter(:profil_user => to_change).delete()
      to_change.destroy
      #IMPORTANT CAR LES ASSOCIATIONS SONT MISE EN CACHE
      refresh
    end
  end

  def add_profil(new_profil)
    np = new_profil
    RoleUser.unrestrict_primary_key()
    ProfilUser.unrestrict_primary_key()
    # ProfilUser sert juste a afficher le profil administratif de l'utilisateur
    ProfilUser.find_or_create(:user => self, 
        :etablissement => np[:etablissement], :profil_id => np[:profil_id])
    #temp : Je ne sais pas si c'est la bonne chose à faire ?
    new_profil = RoleUser.find_or_create(:user => np[:user], 
        :ressource_id => np[:etablissement].id, :ressource_service_id => SRV_ETAB, 
        :role_id => Profil[np[:profil_id]].role_id)
    RoleUser.restrict_primary_key()
    if np[:actif]
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

  def add_parent(parent, type_relation_id=TYP_REL_PAR)
    RelationEleve.unrestrict_primary_key()
    RelationEleve.create(:user_id => parent.id, :eleve_id => self.id, :type_relation_eleve_id => type_relation_id)
  end

  def add_enfant(enfant, type_relation_id=TYP_REL_PAR)
    RelationEleve.unrestrict_primary_key()
    RelationEleve.create(:user_id => self.id, :eleve_id => enfant.id, :type_relation_eleve_id => type_relation_id)
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

  # Rajoute un email à un utilisateur et le met en principal si c'est le premier
  # @param adresse : adresse de l'email
  # @param academique : si oui ou non il s'agit d'un mail académique
  # todo : détecter automatiquement le type académique ?
  def add_email(adresse, academique = false)
    # Si l'utilisateur n'a pas d'email c'est son mail principal
    principal = email.count == 0
    Email.create(:adresse => adresse, :user => self, :academique => academique, :principal => principal)
  end

  def email_principal
    email = email_dataset.filter(:principal => true).first
    return email.nil? ? nil : email.adresse
  end

  def email_academique
    email = email_dataset.filter(:academique => true).first
    return email.nil? ? nil : email.adresse
  end

  # Ajoute un téléphone à l'utilisateur
  # type par défaut Maison mais détecte si c'est un portable
  def add_telephone(numero, type_telephone_id = TYP_TEL_MAIS)
    # On ne détecte le téléphone portable que si on a le type par défaut
    if type_telephone_id == TYP_TEL_MAIS and (numero[0,2] == "06" or numero[0,5] == "+33 6")
      type_telephone_id = TYP_TEL_PORT
    end
    Telephone.create(:numero => numero, :user => self, :type_telephone_id => type_telephone_id)
  end
private
  def regroupements(etablissement_id, type_id)
    service_id = Regroupement.get_service_id(type_id)
    Regroupement.filter(:type_regroupement_id => type_id,
      :etablissement_id => etablissement_id,
      :id => RoleUser.filter(:user => self, :ressource_service_id => service_id).select(:ressource_id))
  end

  def enseigne_regroupements(etablissement_id, type_id)
    Regroupement.filter(:type_regroupement_id => type_id,
      :etablissement_id => etablissement_id,
      :enseigne_regroupement => EnseigneRegroupement.filter(:user => self))
  end
end

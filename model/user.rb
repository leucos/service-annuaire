#coding: utf-8
#
# model for 'user' table
# generated 2012-04-19 17:45:32 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | INT                 | false    | PRI      |            | 
# id_sconet                     | int(11)             | true     | UNI      |            | 
# id_jointure_aaf               | int(11)             | true     | UNI      |            | 
# login                         | varchar(45)         | false    |          |            | 
# password                      | char(60)            | true     |          |            | 
# nom                           | varchar(45)         | false    |          |            | 
# prenom                        | varchar(45)         | false    |          |            | 
# sexe                          | varchar(1)          | true     |          |            | 
# date_naissance                | date                | true     |          |            | 
# adresse                       | varchar(255)        | true     |          |            | 
# code_postal                   | char(6)             | true     |          |            | 
# ville                         | varchar(255)        | true     |          |            | 
# date_creation                 | date                | false    |          |            | 
# date_debut_activation         | date                | true     |          |            | 
# date_fin_activation           | date                | true     |          |            | 
# date_derniere_connexion       | date                | true     |          |            | 
# bloque                        | tinyint(1)          | false    |          | 0          | 
# change_password               | tinyint(1)          | false    |          | 0          | 
# id_ent                        | char(16)            | false    | UNI      |            | 
# avatar                        | varchar(255)        | true     |          |            |
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
require 'carrierwave/sequel'

class User < Sequel::Model(:user)
  # Déclenché quand on tente d'envoyer un mail de regénération de mot de passe
  # sur un email qui nous appartient pas ou qui n'appartient pas aux parents
  class InvalidEmailOwner < StandardError
  end
  # Plugins
  plugin :validation_helpers
  plugin :json_serializer
  plugin :ressource_link, :service_id => SRV_USER
  plugin :fuzzy_search
  plugin :select_json_array

  unrestrict_primary_key()
  # Referential integrity
  one_to_many :enseigne_dans_regroupement
  one_to_many :eleve_dans_regroupement
  one_to_many :role_user
  one_to_many :profil_user
  one_to_many :param_user
  one_to_many :telephone
  one_to_many :email
  one_to_many :membre_regroupement_libre

  # Liste de tous les élèves avec qui l'utilisateur est en relation
  #many_to_many :relation_eleve, :left_key => :user_id, :right_key => :eleve_id, 
    #:join_table => :relation_eleve, :class => self
  many_to_many :enfants, :left_key => :user_id, :right_key => :eleve_id, 
    :join_table => :relation_eleve, :class => self do |ds|
      ds.where(:type_relation_eleve_id => [TYP_REL_PERE, TYP_REL_MERE])
    end
  # Liste de tous les utilisateurs (adultes) avec qui l'élève est en relation
  #many_to_many :relation_adulte, :left_key => :eleve_id, :right_key => :user_id, 
    #:join_table => :relation_eleve, :class => self
  # Liste de tous les parents d'un élève
  many_to_many :parents, :left_key => :eleve_id, :right_key => :user_id, 
    :join_table => :relation_eleve, :class => self do |ds|
      ds.where(:type_relation_eleve_id => [TYP_REL_PERE, TYP_REL_MERE])
    end

  # uploader   
  mount_uploader :avatar, ImageUploader
    
  # Check si l'id passé en paramètre correspond bien aux critères d'identifiant ENT
  def self.is_valid_ent_id?(id)
    !!(id.class == String and id.length == 8 and id[0] == 'V' and id[3] == '6' and id[1..2] =~ /[a-zA-Z]{2}/ and id[4..7] =~ /\d{4}/)
  end

  def self.is_login_available?(login)
    User[:login => login].nil?
  end

  def self.is_login_valid?(login)
    #On créé un utilisateur fictif et on regarde si la validation passe avec ce login
    u = User.new(:login => login, :password => 'a', :nom => 'a', :prenom => 'a')
    return u.valid?
  end

  # Renvois un login composé de 1ere lettre prenom + nom 
  #tout en minuscule, sans espace et sans accents
  def self.get_default_login(prenom, nom)
    login = "#{prenom.strip[0].downcase}#{nom.gsub(/\s+/, "").downcase}"
    #On fait ici de la transliteration (joli hein :) pour éviter d'avoir des accents dans les logins
    login = I18n.transliterate(login)
  end

  # returns available login for a user 
  def self.find_available_login(prenom, nom)
    login = get_default_login(prenom, nom)
    #Si homonymes, on utilise des numéros à la fin
    #todo prendre la deuxième lettre du prenom pour éviter les numéros ?
    login_number = 1
    final_login = login
    while !is_login_available?(final_login)
      final_login = "#{login}#{login_number}"
      login_number += 1
    end

    return final_login
  end

  # Renvois un dataset utilisé pour faire une recherche sur tous les utilisateurs
  # Et formaté pour renvoyé le résultat en JSON
  def self.search_all_dataset
    # Utilise pour l'instant select_json_array!
    # Pour s'en passer, il faudra boucler sur tous les users
    # Et faire une requète pour récupérer les email, puis une pour les téléphones
    # et une pour les profils
    # Surement beaucoup plus lent mais plus standard
    dataset = User.
      select(:user__nom, :user__prenom, :login, :user__id, :user__id_ent, :user__id_jointure_aaf).
      select_json_array!(:emails, {:email__id => "i_id", :email__adresse => "adresse"}).
      select_json_array!(:telephones, {:telephone__id => "i_id", :telephone__numero => "numero"}).
      select_json_array!(:profils, {:profil_national__description => "libelle", :etablissement__nom => "nom"}).
      select_json_array!(:regroupements,{:regroupement__id =>"i_id", :regroupement__libelle_aaf => "libelle", :regroupement__type_regroupement_id => "type"}).
      left_join(:email, :email__user_id => :user__id).
      left_join(:telephone, :telephone__user_id => :user__id).
      left_join(:profil_user, :profil_user__user_id => :user__id).
      left_join(:etablissement, :etablissement__id => :etablissement_id).
      left_join(:profil_national, :id => :profil_user__profil_id).
      left_join(:eleve_dans_regroupement, :eleve_dans_regroupement__user_id => :user__id).
      left_join(:regroupement, :regroupement__id => :eleve_dans_regroupement__regroupement_id).
      group(:user__id)
  end

  # Service de recollement d'un utilisateur pour un établissement
  # param Hash données de l'utilisateur reflétant la structure de la table
  # return nil si 0 ou plusieurs personnes correspondent aux critères
  # return User si seulement une personne correspond aux critères
  def match(user_hash, code_uai)
    # Si le hash provient de l'alimentation automatique
    # On a un id_jointure_aaf
    u = User[:id_jointure_aaf => user_hash[:id_jointure_aaf]] if user_hash[:id_jointure_aaf]
    if u.nil?
      # On utilise les autres infos que l'on a sur l'utilisateur pour le trouver
      # On limite tout de même notre périmètre à l'établissement concerné par l'alimentation
      User.
        filter(:nom.ilike(user[:nom]), :prenom.ilike(user[:prenom]),
        :sexe => user[:sexe], :date_naissance => user[:date_naissance], :id_jointure_aaf => nil,
        :profil_user => ProfilUser.filter(:etablissement => Etablissement.filter(:code_uai => code_uai)))
    end
  end

  # Très important : Hook qui génère l'id unique du user avant de l'inserer dans la BDD
  def before_create
    super
    #puts "self #{self.inspect}"
    if self.id_ent.nil? || self.id_ent.empty?
      self.id_ent = LastUid::get_next_uid()
    end
    self.date_creation ||= Time.now
    super
  end

  def before_destroy
    #Supprime tous les email et les numéros de téléphone du User
    email_dataset.destroy()
    puts "emails deleted !"
    telephone_dataset.destroy()
    puts "telephones deleted !"
    # Supprime aussi toutes les relation_eleve liées au User
    # La syntaxe pour les OR sql est pas évidente je trouve..
    RelationEleve.where(Sequel.expr(:user_id => self.id) | Sequel.expr(:eleve_id => self.id)).destroy()
    puts "relations deleted !"
    # On supprime tous les RoleUser liés à ce User
    role_user_dataset.destroy()
    puts "roles deleted !"
    # Et les enseignements
    EnseigneDansRegroupement.where(:user_id => self.id).destroy()
    puts "groupe deleted !"
    EleveDansRegroupement.where(:user_id => self.id).destroy()
    puts "eleve deleted !"
    #enseigne_dans_regroupement_dataset.destroy()
    MembreRegroupementLibre.where(:user_id => self.id).destroy()
    puts "groupe libre deleted"

    RegroupementLibre.where(:created_by => self.id).destroy()
    # Enfin tous ses profils dans l'établissement
    profil_user_dataset.destroy()
    puts "profil deleted !"

    param_user_dataset.destroy()
    puts "params deleted !"
    super
  end

  # Code très très criticable pour gérer la génération d'uid
  # sur plusieurs process car vu qu'on a un id d'utilisateur non
  # auto incrementé, la génération de l'uid ne gère pas les accès concurrents
  # avant j'avais mis un "LOCK TABLE" pour assurer que personne pouvait y toucher
  # mais ça enlevait la possibilité de faire un rollback en cas d'erreur ou de test.
  # J'ai donc choisi un solution "optimiste" qui consiste à ne pas mettre de lock et
  # catcher l'erreur. Si il s'agit d'une erreur de duplication de primary key,
  # on retente de créer l'utilisateur en esperant que tout se passe bien cette fois.
  # Cette solution à 2 gros défauts :
  # - Elle se base sur le message d'erreur qui est spécifique MySQL pour détecter l'erreur,
  # ce qui est vraiment pas top mais au pire l'exception répercutée...
  # - Elle tente de recréer l'utilisateur ce qui fait que si le processus de generation d'uid est
  # defectueux pour je ne sais quelle raison, on rentre dans une boucle infinie...
  # Si tout va bien, on ne rentrera jamais dans ce code de toute manière, c'est juste au cas ou.
  # Dernière remarque : pour tester ce code, ouvrir 2 ramaze console et taper cela dans la première:
  # 1000.times do |i| User.create(:nom => "test", :prenom => "test", :login => "test#{i}") end
  # et cela dans la deuxième :
  # 1000.times do |i| User.create(:nom => "test", :prenom => "test", :login => "test#{i+1000}") end
  # Executer le code en même temps et vous devrez avoir ce genre d'erreur (tout dépend de votre matériel)
  def around_create
    begin
      super
    rescue Sequel::DatabaseError => e
      # Solution pas terrible car spécifique à MySql mais je vois
      # pas comment autrement
      raise e if e.message.index(/Duplicate entry '.*' for key 'PRIMARY'/).nil?
      #puts e.message 
      # On récupère le hash de l'objet en cours de construction
      hash = self.values
      #puts hash.inspect
      # Et on enlève l'id et la date de création qui seront
      # rajouté par la suite
      hash.delete(:id)
      hash.delete(:date_creation)
      service_id = SRV_USER
      parent_service_id = SRV_ETAB
      parent_id =  hash(:uai)
      # On retente la création de l'objet
      # Attention, ça peut boucler indéfiniment cette histoire...
      User.create(hash)
      Ressource.create(:id => self.id, :service_id => service_id,
            :parent_id => parent_id, :parent_service_id => parent_service_id)
    end
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

  def password
    BCrypt::Password.new(super)
  end

  # Utilise l'algorithme BCrypt pour haser le mot de passe
  def password= (pass)
    super(BCrypt::Password.create(pass))
  end

  # is default password
  def is_default_pass?
    return self.password == self.id_ent+"#{self.id_jointure_aaf}"
  end

  # function initialize passward
  def initialize_password
    self.password = self.id_ent+"#{self.id_jointure_aaf}"
    self.save
  end

  # Renvois toutes les relation_eleve dans lequel est impliqué l'utilisateur
  def relations
    RelationEleve.join(:type_relation_eleve, :id => :type_relation_eleve_id).filter({:eleve_id => self.id, :user_id => self.id}.sql_or).naked.all
  end

  def relations_adultes
    RelationEleve.join(:type_relation_eleve, :type_relation_eleve__id => :type_relation_eleve_id)
    .join(:user, :user__id => :relation_eleve__user_id)
    .filter(:eleve_id => self.id).select(:type_relation_eleve_id, :resp_financier, :resp_legal, :contact, :paiement, :description, :libelle, :id_ent, :nom, :prenom)
    .naked.all
  end

  def relations_eleves
    RelationEleve.join(:type_relation_eleve, :type_relation_eleve__id => :type_relation_eleve_id)
    .join(:user, :user__id => :relation_eleve__eleve_id)
    .filter(:user_id => self.id).select(:type_relation_eleve_id, :resp_financier, :resp_legal, :contact, :paiement, :description, :libelle, :id_ent, :nom, :prenom)
    .naked.all
  end

  def find_relation(eleve)
    RelationEleve.filter(:user_id => self.id, :eleve_id => eleve.id).first
  end

  # Renvoi le premier profil_user trouvé dans un établissement
  # Pas super mais il faut réfléchir à cette notion de profil_actif
  def profil_actif
    profil_user.first
  end

  # Renvois seulement le libelle de profil et le nom de l'établissement de chaque profil
  def profil_user_display
    self.profil_user_dataset
      .join(:etablissement, :id => :etablissement_id)
      .join(:profil_national, :id => :profil_user__profil_id)
      .naked
      .select(:profil_id, :nom___etablissement_nom, :code_uai___etablissement_code_uai, 
        :description___profil_nom, :code_national___profil_code_national, :etablissement_id)
      .all
  end
  
  def role_user_display
    self.role_user_dataset
    .join(:etablissement, :id => :etablissement_id)
    .join(:role, :role__id => :role_user__role_id)
    .naked
    .select(:role_id, :nom___etablissement_nom, :code_uai___etablissement_code_uai, :etablissement_id, :priority, :role__libelle)
    .all
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
      RoleUser.filter(:profil_user => to_change).destroy()
      to_change.destroy
      #IMPORTANT CAR LES ASSOCIATIONS SONT MISE EN CACHE
      refresh
    end
  end

  # Ajoute un profil_user dans l'établissement
  # Et rajoute aussi le role_user associé
  def add_profil(etablissement_id, profil_id)
    # ProfilUser sert juste a afficher le profil administratif de l'utilisateur
    #ProfilUser.find_or_create(:user_id => self.id, 
        #:etablissement_id => etablissement_id, :profil_id => profil_id)
    profil = ProfilUser[:user_id => self.id, 
        :etablissement_id => etablissement_id, :profil_id => profil_id]
    if profil.nil?
      ProfilUser.insert(:user_id => self.id, :etablissement_id => etablissement_id, 
        :profil_id => profil_id)
    else
      profil 
    end
    
    # later i will see the problem of roles commented on 12/03/2013
    add_role(etablissement_id, Profil[profil_id].role_id)
  end

  def add_fonction(etablissement_id, profil_id, fonction_id)
    ProfilUserFonction.find_or_create(:user_id => self.id, 
        :etablissement_id => etablissement_id, :profil_id => profil_id, :fonction_id => fonction_id)
  end   


  def civilite
    sexe == 'F' ? 'Mme' : 'Mr'
  end

  # @return Nom complet de l'utilisateur formatté comme il se doit
  def full_name
    # @todo utiliser un camelize qu'on aura monkey patché a String
    "#{nom.capitalize} #{prenom.capitalize}"
  end

  # def add_or_modify_parent(parent, type_relation_id = 1, resp_financier = 1, resp_legal = 1, contact =1, paiement = 1)
  #   record = RelationEleve[:user_id => parent.id, :eleve_id => self.id, :type_relation_eleve_id => type_relation_id]
  #   if record.nil?
  #     RelationEleve.create(:user_id => parent.id, :eleve_id => self.id, 
  #       :type_relation_eleve_id => type_relation_id, :resp_financier => resp_financier, 
  #       :resp_legal => resp_legal, :contact => contact, :paiement => paiement)
  #   else
  #     record.update(:resp_financier => resp_financier, :resp_legal => resp_legal, 
  #       :contact => contact, :paiement => paiement)
  #   end 
  # end

  def add_parent(parent, type_relation_id = 1, resp_financier = 1, resp_legal = 1, contact =1, paiement = 1)
    record = RelationEleve[:user_id => parent.id, :eleve_id => self.id, :type_relation_eleve_id => type_relation_id]
    if record.nil?
      RelationEleve.create(:user_id => parent.id, :eleve_id => self.id, 
        :type_relation_eleve_id => type_relation_id, :resp_financier => resp_financier, 
        :resp_legal => resp_legal, :contact => contact, :paiement => paiement)
    else
      record.update(:resp_financier => resp_financier, :resp_legal => resp_legal, 
        :contact => contact, :paiement => paiement)
    end 
  end

  def add_enfant(enfant, type_relation_id = TYP_REL_PERE)
    RelationEleve.create(:user_id => self.id, :eleve_id => enfant.id, :type_relation_eleve_id => type_relation_id)
  end

  def delete_relation_eleve(eleve_id)
    self.relation_eleve_dataset.filter(:eleve_id => eleve_id).destroy()
  end

  def etablissements
    ProfilUser.where(:user_id => self.id).map do |profil|
      {:id => profil.etablissement.id, :nom => profil.etablissement.nom}
    end 
    #Etablissement.filter(:id => RoleUser.filter(:ressource_service_id => SRV_ETAB).select(:ressource_id))
    RoleUser.filter(:user_id => self.id).map do |role|
      {:id => role.etablissement_id, :nom => Etablissement[:id => role.etablissement_id].nom}
    end
  end

  def applications
    ids = etablissements.collect{ |x| x[:id]}
    Application.join(:application_etablissement, :application_id => :id).join(:etablissement, :etablissement__id => :etablissement_id).where(:etablissement_id => ids)
    .select(:application__id, :application__libelle, :application__description, :application__url, :application_etablissement__active, :application_id, :etablissement_id, :etablissement__code_uai___etablissement_code_uai).naked.all
  end

  def add_to_regroupement(regroupement_id)
    EleveDansRegroupement.find_or_create(:user_id => self.id, :regroupement_id => regroupement_id)
  end

  # Ajoute un role sur une classe
  def add_classe(classe_id, role_id)
    add_role(classe_id, TYP_REG_CLS, role_id)
  end


  ########################## 
  #    classes eleve       #
  ##########################

  #toutes les classes dans lesquelles l'eleve est inscrit
  def classes_eleve(etablissement_id = nil)
    regroupement_eleve =  self.eleve_dans_regroupement.map do |eleve_regroupement|
      {:id => eleve_regroupement.regroupement_id, :etablissement_id => eleve_regroupement.regroupement.etablissement_id, 
      :type_regroupement => eleve_regroupement.regroupement.type_regroupement_id, 
      :libelle => eleve_regroupement.regroupement.libelle_aaf }
    end
    if etablissement_id.nil? # return all etablissements
      return regroupement_eleve.select{|r| r[:type_regroupement] == TYP_REG_CLS}
    else
      return regroupement_eleve.select{|r| r[:type_regroupement] == TYP_REG_CLS && r[:etablissement_id] == etablissement_id} 
    end 
  end

  # user readable format of student classes
  def classes_eleve_display
    # case of an (eleve)
    # need to rename the dataset select
    self.eleve_dans_regroupement_dataset
    .join(:regroupement, :id => :regroupement_id)
    .join(:etablissement, :id => :etablissement_id)
    .where(:type_regroupement_id => 'CLS').naked
    .select(:code_uai___etablissement_code, :regroupement_id___classe_id, :libelle_aaf___classe_libelle, :nom___etablissement_nom, :etablissement_id)
    .all
  end  

  def groupes_eleve_display
    # case of an (eleve)
    # need to rename the dataset select
    self.eleve_dans_regroupement_dataset
    .join(:regroupement, :id => :regroupement_id)
    .join(:etablissement, :id => :etablissement_id)
    .where(:type_regroupement_id => 'GRP').naked
    .select(:code_uai___etablissement_code, :regroupement_id___groupe_id, :libelle_aaf___groupe_libelle, :nom___etablissement_nom, :etablissement_id)
    .all
  end  

  def cpe_groupes_display
    # users with profil cpe
    profils_cpe = ProfilUser.filter(:user_id => self.id, :profil_id =>["DIR", "DOC", "EVS"]).all
    groupes = []
    if !profils_cpe.empty?
      profils_cpe.each do |profil|
        groupes = groupes.concat(
          Regroupement.join(:etablissement, :etablissement__id => :regroupement__etablissement_id)
          .filter(:regroupement__type_regroupement_id => 'GRP', :regroupement__etablissement_id => profil.etablissement_id)
          .naked
          .select(:code_uai___etablissement_code, :regroupement__id___groupe_id, :libelle_aaf___groupe_libelle, :nom___etablissement_nom, :etablissement_id)
          .all
          )
      end
    end

    #user with role admin etablissement
    role_admin = RoleUser.filter(:user_id => self.id, :role_id => ROL_ADM_ETB)
    if !role_admin.empty?
      role_admin.each  do |role|
        groupes = groupes.concat(
          Regroupement.join(:etablissement, :etablissement__id => :regroupement__etablissement_id)
          .filter(:regroupement__type_regroupement_id => 'GRP', :regroupement__etablissement_id => role.etablissement_id)
          .naked
          .select(:code_uai___etablissement_code, :regroupement__id___groupe_id, :libelle_aaf___groupe_libelle, :nom___etablissement_nom, :etablissement_id)
          .all
          )
      end
    end
    groupes.uniq
  end
  #Groupes auxquel l'élève est inscrit
  def groupes_eleve(etablissement_id = nil)
    regroupement_eleve =  self.eleve_dans_regroupement.map do |eleve_regroupement|
      {:id => eleve_regroupement.regroupement_id, :etablissement_id => eleve_regroupement.regroupement.etablissement_id, 
      :type_regroupement => eleve_regroupement.regroupement.type_regroupement_id, 
      :libelle => eleve_regroupement.regroupement.libelle_aaf}
    end
    if etablissement_id.nil? # return all etablissements
      return regroupement_eleve.select{|r| r[:type_regroupement] == TYP_REG_GRP}
    else
      return regroupement_eleve.select{|r| r[:type_regroupement] == TYP_REG_GRP && r[:etablissement_id] == etablissement_id} 
    end 
  end

  def groupes_libres
    self.membre_regroupement_libre_dataset
    .join(:regroupement_libre, :id => :regroupement_libre_id)
    .left_join(:user, :user__id => :created_by).naked
    .select(:regroupement_libre_id, :joined_at, :created_at, :id_ent___created_by, :libelle).all
    #regroupements(etablissement_id, TYP_REG_LBR)
  end


  #################################### 
  #    classes prof                  #
  ####################################
  #toutes les classes dans lesquelles l'utilisateur enseigne
  def enseigne_classes(etablissement_id = nil)
    regroupement_enseingant = self.enseigne_dans_regroupement.map do |enseigne_regroupement|
      {:id => enseigne_regroupement.regroupement_id, :etablissement_id => enseigne_regroupement.regroupement.etablissement_id, 
      :type_regroupement => enseigne_regroupement.regroupement.type_regroupement_id, 
      :libelle => enseigne_regroupement.regroupement.libelle_aaf}
    end
    if etablissement_id.nil? # return all etablissements
      return regroupement_enseingant.select{|r| r[:type_regroupement] == TYP_REG_CLS}
    else
      return regroupement_enseingant.select{|r| r[:type_regroupement] == TYP_REG_CLS && r[:etablissement_id] == etablissement_id} 
    end 
  end

  # user readable format of enseigne classes
  def enseigne_classes_display
    self.enseigne_dans_regroupement_dataset.join(:regroupement, :regroupement__id =>:regroupement_id)
    .join(:etablissement, :etablissement__id => :etablissement_id)
    .join(:matiere_enseignee, :matiere_enseignee__id => :enseigne_dans_regroupement__matiere_enseignee_id)
    .where(:type_regroupement_id => 'CLS')
    .select(:code_uai___etablissement_code, :libelle_aaf___classe_libelle, :nom___etablissement_nom, 
      :matiere_enseignee_id, :libelle_long___matiere_libelle, :regroupement_id___classe_id, :etablissement_id, :prof_principal)
    .naked.all
  end

  def cpe_classes_display
    profils_cpe = ProfilUser.filter(:user_id => self.id, :profil_id =>["DIR", "DOC", "EVS"]).all
    classes = []
    if !profils_cpe.empty?
      profils_cpe.each do |profil|
        classes = classes.concat(
          Regroupement.join(:etablissement, :etablissement__id => :regroupement__etablissement_id).filter(:regroupement__type_regroupement_id => 'CLS', :regroupement__etablissement_id => profil.etablissement_id).naked
          .select(:code_uai___etablissement_code, :regroupement__id___classe_id, :libelle_aaf___classe_libelle, :nom___etablissement_nom, :etablissement_id)
          .all
          )
      end
    end

    role_admin = RoleUser.filter(:user_id => self.id, :role_id => ROL_ADM_ETB)
    if !role_admin.empty?
      role_admin.each  do |role|
        classes = classes.concat(
          Regroupement.join(:etablissement, :etablissement__id => :regroupement__etablissement_id).filter(:regroupement__type_regroupement_id => 'CLS', :regroupement__etablissement_id => role.etablissement_id).naked
          .select(:code_uai___etablissement_code, :regroupement__id___classe_id, :libelle_aaf___classe_libelle, :nom___etablissement_nom, :etablissement_id)
          .all
          )
      end
    end
    classes.uniq
  end

  def enseigne_groupes_display
    self.enseigne_dans_regroupement_dataset
    .join(:regroupement, :regroupement__id => :regroupement_id)
    .join(:etablissement, :etablissement__id => :etablissement_id)
    .join(:matiere_enseignee, :matiere_enseignee__id => :enseigne_dans_regroupement__matiere_enseignee_id)
    .where(:type_regroupement_id => 'GRP')
    .select(:code_uai___etablissement_code, :libelle_aaf___groupe_libelle, :nom___etablissement_nom, :matiere_enseignee_id, :libelle_long___matiere_libelle, :regroupement_id___groupe_id, :etablissement_id)
    .naked.all
  end 

  ########################## 
  #    classes parent      #
  ##########################
  # user readable format of parent classes( note that parent classes are his childerens classes)
  def parent_classes_display
    parent_classes = []
    self.enfants.each do |enfant|
      parent_classes = parent_classes.concat(enfant.classes_eleve_display)
    end
    parent_classes   
  end

  def parent_groupes_display
    parent_groupes = []
    self.enfants.each do |enfant|
      parent_groupes = parent_groupes.concat(enfant.groupes_eleve_display)
    end
    parent_groupes  
  end 

  ######################## 

  # a function that returns classes for all profils
  def classes_display
    enseigne_classes_display.concat(classes_eleve_display).concat(parent_classes_display).concat(cpe_classes_display).uniq{|x| [x[:classe_id], x[:matiere_enseignee_id]]}
  end 

  def groupes_display
    enseigne_groupes_display.concat(groupes_eleve_display).concat(parent_groupes_display).concat(cpe_groupes_display).uniq{|x| [x[:groupe_id], x[:matiere_enseignee_id]]}
  end

  # Groupes auxquel l'utilisateur enseinge
  def enseigne_groupes(etablissement_id = nil)
    regroupement_enseingant = self.enseigne_dans_regroupement.map do |enseigne_regroupement|
      {:id => enseigne_regroupement.regroupement_id, :etablissement_id => enseigne_regroupement.regroupement.etablissement_id, 
      :type_regroupement => enseigne_regroupement.regroupement.type_regroupement_id, 
      :libelle => enseigne_regroupement.regroupement.libelle_aaf}
    end
    if etablissement_id.nil? # return all etablissements
      return regroupement_enseingant.select{|r| r[:type_regroupement] == TYP_REG_GRP}
    else
      return regroupement_enseingant.select{|r| r[:type_regroupement] == TYP_REG_GRP && r[:etablissement_id] == etablissement_id} 
    end
  end

  # retourne les matieres enseignees par l'utilisateur dans l'etablissement dont l'id = etablissement_id 
  def matieres_enseignees
    self.enseigne_dans_regroupement_dataset.join(:regroupement, :regroupement__id => :regroupement_id)
    .join(:matiere_enseignee, :matiere_enseignee__id => :enseigne_dans_regroupement__matiere_enseignee_id)
    .join(:etablissement, :etablissement__id => :regroupement__etablissement_id)
    .naked.select(:regroupement_id, :matiere_enseignee_id, :prof_principal, :libelle_aaf, :type_regroupement_id, :libelle_long, :code_uai)
    .all
  end


  def matiere_enseigne(etablissement_id)
    MatiereEnseignee.
      filter(:enseigne_dans_regroupement => EnseigneDansRegroupement.
        filter(:user => self, :regroupement => Regroupement.
          filter(:etablissement_id => etablissement_id))).all
  end

  # retourne les matieres enseignees par l'utilisateur dans un groupe dont i'id = groupe_id
  def matiere_enseigne(groupe_id)
    MatiereEnseignee.
      filter(:enseigne_dans_regroupement => EnseigneDansRegroupement.
        filter(:user => self, :regroupement_id  => groupe_id)).naked.all
  end

  def prof_principal(groupe_id)
    edr = EnseigneDansRegroupement[:user_id => self.id, :regroupement_id=> groupe_id]
    if edr 
      edr.prof_principal
    else
      "N"
    end 
  end 

  # Rajoute un email à un utilisateur et le met en principal si c'est le premier
  # @param adresse : adresse de l'email
  # @param academique : si oui ou non il s'agit d'un mail académique
  # todo : détecter automatiquement le type académique ?
  def add_email(adresse, academique = false)
    # Si l'utilisateur n'a pas d'email c'est son mail principal
    #principal = (Email.filter(:user_id => self.id).count == 0)
    Email.filter(:user_id => self.id).count == 0 ? principal = 1 : principal = 0
    #mail = Email.find_or_create(:adresse => adresse, :user_id => self.id)
    mail = Email[:adresse => adresse, :user_id => self.id]
    if mail
      mail.principal = principal
      mail.academique = academique
      mail.save
    else
      mail = Email.create(:adresse => adresse, :user_id => self.id, :principal => principal)
      mail.principal = principal
      mail.academique = academique
      mail.save
    end
  end

  def delete_email(adresse)
    email = Email[:adresse => adresse , :user => self]
    email.destroy  unless email.nil? 
  end 

  def email_principal
    email = email_dataset.filter(:principal => true).first
    return email.nil? ? nil : email.adresse
  end

  def email_academique
    email = email_dataset.filter(:academique => true).first
    return email.nil? ? nil : email.adresse
  end

  # Permet de savoir si l'email passé en paramètre appartient bien à l'utilisateur
  # param Email
  # return true or false
  def has_email(adresse)
    self.email.index{|e| e.adresse == adresse} != nil
  end

  # Ajoute un téléphone à l'utilisateur
  # type par défaut Maison mais détecte si c'est un portable
  def add_telephone(numero, type_telephone_id = TYP_TEL_MAIS)
    Telephone.find_or_create(:numero => numero, :user_id => self.id, :type_telephone_id => type_telephone_id)
  end

  # Set la valeur d'une préférence sur un utilisateur
  # @param valeur, si nil alors détruit la préférence
  def set_preference(preference_id, valeur)
    param = ParamUser[:user => self, :param_application_id => preference_id]
    if param
      if valeur
        param.update(:valeur => valeur)
      else
        param.destroy()
      end
    elsif valeur
      ParamUser.create(:user => self, :param_application_id => preference_id, :valeur => valeur)
    end
  end

  # Renvois les preferences d'un utilisateur sur une application
  # les valeurs sont celles par défaut si l'utilisateur n'a rien précisé
  def preferences(application_id)
    DB[:param_application].
      join_table(:left, :param_user, {:param_application_id => :id, :user_id => self.id}).
      filter(:application_id => application_id, :preference => true).
      select(:code, :valeur_defaut, :valeur, :libelle, :description, :autres_valeurs, :type_param_id).
      all
  end

  # renvois tous les droits 
  def rights(etablissement_id = nil)
    rights = Rights.resolve_rights(self.id, etablissement_id)
    return rights
  end

  def add_role(etablissement_id, role_id)
    RoleUser.find_or_create(:user_id => self.id, :role_id => role_id,
      :etablissement_id => etablissement_id)
  end

  # Créé une session utilisateur temporaire
  # pour permettre à la personne de se connecter sans login/mdp
  # puis met le flag change_password à true
  # et envois un mail avec une url contenant la clé de session
  # Il ne sera pas demandé à l'utilisateur de se logué car il a une session
  # et comme le flag change_password est à true, on lui demandera
  # en premier lieu de changer son password
  # todo : faire passer ça dans sidekick et à un système d'envois de mail centralisé avec template
  def send_password_mail(adresse)
    # On envois que si le mail nous appartient ou appartient à nous parent
    is_parent_mail = parents.index{|p| p.has_email(adresse)} != nil
    if has_email(adresse) or is_parent_mail
      self.update(:change_password => true)
      session_key = AuthSession.create(self.id, EMAIL_DURATION)
      full_name = self.full_name
      mail = Mail.new do
        to adresse
        from "noreply@laclasse.com"
        subject "[laclasse.com] Veuillez réinitialiser votre mot de passe"
        # todo : ne pas mettre l'adresse laclasse.com en dur
        body(
            "Bonjour,

            Il semblerait que #{is_parent_mail ? 'votre enfant ' + full_name + ' a' :'vous avez'} perdu #{is_parent_mail ? 'son':'votre'} mot de passe laclasse.com.
            Si c'est le cas, merci de suivre dans les prochaines #{EMAIL_DURATION/3600}h le lien ci-dessous afin de réinitialiser #{is_parent_mail ? 'son':'votre'} mot de passe :
            https://www.laclasse.com/?session_key=#{session_key}

            Si vous #{is_parent_mail ? '(ou votre enfant) ':''}n'avez pas fait de demande de réinitialisation de mot de passe, merci d'ignorer ce message.
            Sachez qu'il #{is_parent_mail ? '':'vous '}sera tout de même demandé #{is_parent_mail ? 'à votre enfant ':''}de changer de mot de passe lors de #{is_parent_mail ? 'sa':'votre'} prochaine connexion.

            Cordialement,

            L'équipe laclasse.com")
      end
      # Dommage que l'on ne peut pas préciser ça dans le deliver...
      mail.charset = 'utf-8'
      mail.deliver
    else
      raise InvalidEmailOwner
    end
  end

  def is_eleve?
    ProfilUser.filter(:user_id => self.id, :profil_id =>PRF_ELV).empty? ? false : true
    #ou role 
  end

  def is_tuteur?
    ProfilUser.filter(:user_id => self.id, :profil_id =>PRF_PAR).empty? ? false : true
  end

  def is_enseignant?
    ProfilUser.filter(:user_id => self.id, :profil_id =>PRF_ENS).empty? ? false : true
  end

  def add_to_groupe_libre(groupe_id)
    membre = MembreRegroupementLibre[:user_id => self.id, :regroupement_libre_id => groupe_id]
    if membre
      membre
    else
      MembreRegroupementLibre.create(:user_id => self.id, :regroupement_libre_id => groupe_id, :joined_at => DateTime.now)
    end
  end


  # Actuellement le traitement est statique
  # donc, si on ajoute des roles ...? 
  def responsableOf
    ids = []
    self.role_user.each do |role|
      if role[:role_id]=="TECH"
        ids = ProfilUser.join(:user, :id => :user_id).filter(:profil_id => "ELV")
            .select(:id_ent).naked.all.map{|r| r[:id_ent]}
        #profil eleve only
      elsif role[:role_id]=="ELV_ETB"
        ids
      elsif role[:role_id]=="PROF_ETB"
        classes = self.enseigne_classes_display
        eleves = []
        classes.each do |c|
          eleves = eleves.concat(Regroupement[c[:classe_id]].eleves.map{|r| r[:id_ent]})
        end
        groupes=self.enseigne_groupes_display
        groupes.each do |g|
          eleves = eleves.concat(Regroupement[g[:groupe_id]].eleves.map{|r| r[:id_ent]})
        end
        ids = ids.concat(eleves)
        # retourner les eleve dans ses classe/groupe
      elsif role[:role_id]=="ADM_ETB" || role[:role_id]=="DIR_ETB"||role[:role_id]=="CPE_ETB" ||role[:role_id]=="AVS_ETB"
        etab = Etablissement[:id => role[:etablissement_id]]
        eleves = etab.eleves.map{|r| r[:id_ent]}
        ids = ids.concat(eleves) 
      elsif role[:role_id] =="PAR_ETB"
        ids
      end
    end
    ids.uniq
  end
  
private
  
  def regroupements(etablissement_id, type_id)
    ds = Regroupement.filter(:type_regroupement_id => type_id,
      :id => RoleUser.filter(:user => self, :ressource_service_id => type_id).select(:ressource_id))
    ds = ds.filter(:etablissement_id => etablissement_id) if etablissement_id
    return ds.all
  end

  def enseigne_regroupements(etablissement_id, type_id)
    Regroupement.filter(:type_regroupement_id => type_id,
      :etablissement_id => etablissement_id,
      :enseigne_dans_regroupement => EnseigneDansRegroupement.filter(:user => self))
  end

end

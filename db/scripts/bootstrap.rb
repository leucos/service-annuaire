#encoding: utf-8
require 'sequel'
require_relative '../../config/database'
require_relative '../../model/init'

def create_super_admin_and_ressource_laclasse()
  # laclasse est un ressource un peu spéciale car elle ne correspond pas a quelque chose en mémoire
  #Création de la ressource laclasse avec l'id externe 0 qui correspond à rien
  r = Ressource.create(:id => 0, :service_id => SRV_LACLASSE)
  #Création du compte super admin
  u = User.create(:nom => "Super", :prenom => "Didier", :sexe => "M", :login => "root", :password => "root")
  RoleUser.create(:user_id => u.id, :ressource_id => r.id, :ressource_service_id => r.service_id, :role_id => ROL_TECH)
end

def truncate_ressource()
  # La suppression des ressource est un peu spéciale vu qu'il y a un lien de parentalité dans la table
  # Pour ne pas se compliquer la vie on enlève temporairement le check sur les foreign key
  DB.run("SET FOREIGN_KEY_CHECKS = 0;")

  DB[:ressource].truncate()

  DB.run("SET FOREIGN_KEY_CHECKS = 1;")
end
##
## ATTENTION : A NE SURTOUT PAS UTILISER EN PRODUCTION
## SUPPRIME TOUTE LA BDD !!!!!!!
##
def clean_annuaire()
  puts "TRUNCATE ALL USER RELATED TABLES"
  [
    :last_uid, :telephone, :email, :relation_eleve, :ressource,
    :enseigne_dans_regroupement, :role_user, :profil_user, :user, :regroupement, :eleve_dans_regroupement, :regroupement_libre, :membre_regroupement_libre 
  ].each do |table|
    if table == :ressource
      truncate_ressource()
    else    
      DB[table].truncate()
    end
  end

  create_super_admin_and_ressource_laclasse()
end

def bootstrap_annuaire()
  #puts "truncateNCATE ALL TABLES"
  #ATTENTION : CODE SPECIFIQUE MYSQL
  #On ne peut pas faire un bete DB.tables.each car il faut respecter l'ordre des foreign keys
  # TODO : supprimer les ressources en faisant attention aux parents
  #:last_uid, :activite_role, :role_user, :activite, :role, :param_application, :type_param, :ressource, :service, :email,
  #:telephone, :profil_user, :etablissement, :enseigne_dans_regroupement, :regroupement, :application_etablissement,
  #:user, :type_telephone, :type_regroupement, :type_relation_eleve, :profil_national, :niveau, :relation_eleve, :eleve_dans_regroupement
  [
  :activite_role, :role_user, :activite, :role, :param_application, :type_param, :ressource, :service, :profil_national
  ].each do |table|
    if table == :ressource
      truncate_ressource()
    else
      DB.run("SET FOREIGN_KEY_CHECKS = 0;")    
      DB[table].truncate()
      DB.run("SET FOREIGN_KEY_CHECKS = 1;")
    end
  end

  #-----------------------------------------------------#
  # insert default data 
  puts "INSERT STATIC DATA"
  # Niveau alimenter par mef educ nat 

  #----------------------------------------------------------------------#
  # type Etablissement
=begin
  type_etb = TypeEtablissement.create({:nom => 'Service du département', :type_contrat => 'PU'})
  erasme = Etablissement.create(:nom => 'ERASME', :type_etablissement_id =>type_etb.id)

  #Des établissements
  #Les id d'établissement correspondent à des vrais identifiant pour tester l'alimentation automatique
  TypeEtablissement.create(:nom => 'Ecole', :type_contrat => 'PR', :libelle => 'Ecole privée')
  TypeEtablissement.create(:nom => 'Ecole', :type_contrat => 'PU', :libelle => 'Ecole publique')
  TypeEtablissement.create(:nom => 'Collège', :type_contrat => 'PR', :libelle => 'Collège privé')
  type_etb = TypeEtablissement.create(:nom => 'Collège', :type_contrat => 'PU', :libelle => 'Collège public')
  TypeEtablissement.create(:nom => 'Lycée', :type_contrat => 'PR', :libelle => 'Lycée privé')
  TypeEtablissement.create(:nom => 'Lycée', :type_contrat => 'PU', :libelle => 'Lycée public')
  TypeEtablissement.create(:nom => 'Bâtiment', :type_contrat => 'PU', :libelle => 'Bâtiment public')
  TypeEtablissement.create(:nom => 'Lycée professionnel', :type_contrat => 'PR', :libelle => 'Lycée professionnel privé')
  TypeEtablissement.create(:nom => 'Lycée professionnel', :type_contrat => 'PU', :libelle => 'Lycée professionnel public')
  TypeEtablissement.create(:nom => 'Maison Familiale Rurale', :type_contrat => 'PU', :libelle => 'Maison Familiale Rurale')
  TypeEtablissement.create(:nom => 'Campus', :type_contrat => 'PU', :libelle => 'Campus public')
  TypeEtablissement.create(:nom => 'CRDP', :type_contrat => 'PU', :libelle => 'Centre Régional de Documentation Pédagogique')
  TypeEtablissement.create(:nom => 'CG Jeunes', :type_contrat => 'PU', :libelle => 'CG Jeunes')
  TypeEtablissement.create(:nom => 'Cité scolaire', :type_contrat => 'PR', :libelle => 'Cité scolaire privée')
  TypeEtablissement.create(:nom => 'Cité scolaire', :type_contrat => 'PU', :libelle => 'Cité scolaire publique')
  
  #--------------------------------------------------------------------------#
  # Type Telephone
  TypeTelephone.create(:id => TYP_TEL_MAIS, :libelle => 'Maison')
  TypeTelephone.create(:id => TYP_TEL_PORT, :libelle => 'Portable')
  TypeTelephone.create(:id => TYP_TEL_TRAV, :libelle => 'Travail')
  TypeTelephone.create(:id => TYP_TEL_AUTR, :libelle => 'Autre')

  #--------------------------------------------------------#
  # TODO : à modifier car on des nouveaux données
  TypeRelationEleve.create(:id => 1, :libelle => 'PERE', :description => "Père")
  TypeRelationEleve.create(:id => 2, :libelle => 'MERE', :description => "Mère")
  TypeRelationEleve.create(:id => 3, :libelle => 'TUTEUR', :description => "Tuteur")
  TypeRelationEleve.create(:id => 4, :libelle => 'A_MMBR', :description => "Autre membre de la famille")
  TypeRelationEleve.create(:id => 5, :libelle => 'DDASS', :description => "Ddass")
  TypeRelationEleve.create(:id => 6, :libelle => 'A_CAS', :description => "Autre cas")
  TypeRelationEleve.create(:id => 7, :libelle => 'ELEVE', :description => "Eleve lui meme")

  #--------------------------------------------------------#
  # Type Regroupement
  TypeRegroupement.create(:id => TYP_REG_CLS, :libelle => 'Classe')
  TypeRegroupement.create(:id => TYP_REG_GRP, :libelle => "Groupe d'élèves")
  TypeRegroupement.create(:id => TYP_REG_LBR, :libelle => "Groupe libre")
 
  

=end 

  #--------------------------------------------------------------------------#
  # Création des activités
  Activite.create(:id => ACT_CREATE)
  Activite.create(:id => ACT_READ)
  Activite.create(:id => ACT_UPDATE)
  Activite.create(:id => ACT_DELETE)
  Activite.create(:id => ACT_MANAGE)
  #--------------------------------------------------------------------------#

  # Création des services
  #Tout d'abord, on créer des services (api)
  #service laclasse.com (les super admin y sont reliés)
  Service.create(:id => SRV_LACLASSE, :libelle => "Laclasse.com", :description => "Service auquel tout est rattaché", :url => "/")
  Service.create(:id => SRV_USER, :libelle => "Utilisateur", :description => "Service de gestion des utilisateurs de laclasse.com", :url => "/user")
  Service.create(:id => SRV_ETAB, :libelle => "Etablissement", :description => "Service de gestion des etablissements de laclasse.com", :url => "/etablissement")
  Service.create(:id => SRV_CLASSE, :libelle => "Classes", :url => "/classe")
  # service /groupe
  Service.create(:id => SRV_GROUPE, :libelle => "Groupes d'élèves", :url => "/groupe")
  # service /libre
  Service.create(:id => SRV_LIBRE, :libelle => "Groupes libres", :url => "/libre")
  # service /application
  Service.create(:id => SRV_APP, :libelle => "Applications", :url => "/app")
  # service /role 
  Service.create(:id => SRV_ROLE, :libelle => "Roles", :url => "/role")
  
  Service.create(:id => SRV_DOC, :libelle => "Documents",:url =>"/docs")

  # service params
  Service.create(:id => SRV_PARAM, :libelle => "parameters", :url=> "/params")
  # TODO 
  # service /alimentation
  # service /preference 
  # service /application
  # service /rights 


  
  # TODO : Rajouter les roles de prof et eleve dans une classe (cela sera des constantes)
  # TODO : Rajouter le role de documentaliste qui a comme une role de prof sur toutes les classes
  # (accès aux documents, cahier de texte) sans avoir besoin de s'y rattacher
  #---------------------------------------------------------------------------#

  # Création de root ressource Laclasse 
  Ressource.create(:id => 0, :service_id => SRV_LACLASSE)

  # Création des Roles et definitions des activités 
  # Role => admin Laclasse
  role_tech = Role.create(:id => ROL_TECH, :libelle => "Administrateur technique", :priority =>3 )
  # Activities => 
  role_tech.add_activite(SRV_USER, ACT_MANAGE, "all", SRV_LACLASSE)
  role_tech.add_activite(SRV_ETAB, ACT_MANAGE, "all", SRV_LACLASSE)
  role_tech.add_activite(SRV_CLASSE, ACT_MANAGE, "all", SRV_LACLASSE)
  role_tech.add_activite(SRV_GROUPE, ACT_MANAGE, "all", SRV_LACLASSE)
  role_tech.add_activite(SRV_LIBRE, ACT_MANAGE, "all", SRV_LACLASSE)
  role_tech.add_activite(SRV_APP, ACT_MANAGE, "all", SRV_LACLASSE)
  role_tech.add_activite(SRV_ROLE, ACT_MANAGE, "all", SRV_LACLASSE)
  
  #Service Document 
  role_tech.add_activite(SRV_DOC, ACT_MANAGE, "all", SRV_LACLASSE)

  #Service Role 

  #---------------------------------------------------------------------------#
  # Role => admin Etab 
  role_admin = Role.create(:id => ROL_ADM_ETB, :libelle => "Administrateur d'établissement", :priority =>2 )


  # activities 
    # can manage User belongs to his etablissement 
    # can upadate Etab belongs to his etab 
    # can read all etablissements 
    # can manage classes belong to his etab 
    # can manage groupes belogns to his etab 
    #
  # Activities => etablissement level 
  role_admin.add_activite(SRV_USER, ACT_MANAGE, "belongs_to", SRV_ETAB)
  role_admin.add_activite(SRV_ETAB, ACT_UPDATE, "belongs_to", SRV_ETAB)
  
  #role_admin.add_activite(SRV_ETAB, ACT_READ, "belongs_to", SRV_ETAB)
  role_admin.add_activite(SRV_CLASSE, ACT_MANAGE, "belongs_to", SRV_ETAB)
  role_admin.add_activite(SRV_GROUPE, ACT_MANAGE, "belongs_to", SRV_ETAB)
  
  # service Document 
  role_admin.add_activite(SRV_DOC, ACT_MANAGE, "belongs_to", SRV_ETAB)
  role_admin.add_activite(SRV_LIBRE, ACT_MANAGE, "belongs_to", SRV_ETAB)
  role_admin.add_activite(SRV_APP, ACT_MANAGE, "belongs_to", SRV_ETAB)

  # it is not neccessary because admin etablissement can only accord roles to 
  # other users 
  # role_admin.add_activite(SRV_ROLE, ACT_MANAGE, "belongs_to", SRV_ETAB)
  
  # Activities => laclasse(root) level
  role_admin.add_activite(SRV_ETAB, ACT_READ, "belongs_to", SRV_LACLASSE)

  # note: distinguish between: 
  # update SRV_ETAB belongs_to SRV_LaCLASSE or update All ?!! 

  
  #---------------------------------------------------------------------------#
  # Role => Prof  
  prof_role = Role.create(:id => ROL_PROF_ETB, :libelle => "Professeur", :priority => 1)
  
  # Activities => etablissement level 
  prof_role.add_activite(SRV_USER, ACT_READ, "belongs_to", SRV_ETAB)
  prof_role.add_activite(SRV_CLASSE, ACT_READ, "belongs_to", SRV_ETAB)
  prof_role.add_activite(SRV_GROUPE, ACT_READ, "belongs_to", SRV_ETAB)
  prof_role.add_activite(SRV_ETAB, ACT_READ, "belongs_to",SRV_ETAB)

  # Activities => class or group level 
  prof_role.add_activite(SRV_USER, ACT_MANAGE, "belongs_to", SRV_CLASSE)
  prof_role.add_activite(SRV_CLASSE, ACT_READ, "belongs_to", SRV_CLASSE)
  prof_role.add_activite(SRV_CLASSE, ACT_UPDATE, "belongs_to", SRV_CLASSE)
  prof_role.add_activite(SRV_GROUPE, ACT_READ, "belongs_to", SRV_GROUPE)
  prof_role.add_activite(SRV_GROUPE, ACT_UPDATE, "belongs_to", SRV_GROUPE)
  #TODO: add role et app activities
  
  # Activities => Documents activites 
  prof_role.add_activite(SRV_DOC, ACT_MANAGE, "self", SRV_ETAB)

  # activities on himself 
  prof_role.add_activite(SRV_USER, ACT_UPDATE, "self", SRV_USER)

  # This is not neccessary 
  prof_role.add_activite(SRV_USER, ACT_READ, "self", SRV_USER)
  #---------------------------------------------------------------------------#
  # Role => eleve
  role_eleve = Role.create(:id => ROL_ELV_ETB, :libelle => "Elève")
  # add activities on etablissement level
  role_eleve.add_activite(SRV_ETAB, ACT_READ,   "belongs_to", SRV_ETAB)
  role_eleve.add_activite(SRV_CLASSE, ACT_READ, "belongs_to", SRV_ETAB)
  role_eleve.add_activite(SRV_GROUPE, ACT_READ, "belongs_to", SRV_ETAB)
  role_eleve.add_activite(SRV_DOC, ACT_READ, "belongs_to", SRV_ETAB)
  
  # add activities on classe level 
  role_eleve.add_activite(SRV_CLASSE, ACT_READ, "belongs_to", SRV_CLASSE)
  role_eleve.add_activite(SRV_GROUPE, ACT_READ, "belongs_to", SRV_GROUPE)
  role_eleve.add_activite(SRV_USER, ACT_READ, "belongs_to", SRV_CLASSE)
  role_eleve.add_activite(SRV_DOC, ACT_MANAGE, "self", SRV_CLASSE)
  role_eleve.add_activite(SRV_DOC, ACT_MANAGE, "self", SRV_GROUPE)
  
  # add activities on user level(himself)
  role_eleve.add_activite(SRV_USER, ACT_UPDATE, "self", SRV_USER)
  role_eleve.add_activite(SRV_USER, ACT_READ, "self", SRV_USER)
  
  #----------------------------------------------------------------------------#
  # Role => parent
  role_parent = Role.create(:id => ROL_PAR_ETB, :libelle => "Parent")
  # role parent
      # can :read etablissment in which he has a profil
      # can :read classes in the etablissement 
      # can :read groups in the etablissement
  role_parent.add_activite(SRV_ETAB, ACT_READ,   "belongs_to", SRV_ETAB)
  role_parent.add_activite(SRV_CLASSE, ACT_READ, "belongs_to", SRV_ETAB)
  role_parent.add_activite(SRV_GROUPE, ACT_READ, "belongs_to", SRV_ETAB) 

  # add activities on classe level
  # can read classes of his child(ren)
  # can read groupes of his child(ren)
  # can read users in his child(ren) classes
  # can read his son info ?!
  role_parent.add_activite(SRV_CLASSE, ACT_READ, "belongs_to", SRV_CLASSE)
  role_parent.add_activite(SRV_GROUPE, ACT_READ, "belongs_to", SRV_GROUPE)
  role_parent.add_activite(SRV_USER, ACT_READ, "belongs_to", SRV_CLASSE)


  #add activities on user level
  # can read himself 
  # can update himself 
  role_parent.add_activite(SRV_USER, ACT_UPDATE, "self", SRV_USER)
  role_parent.add_activite(SRV_USER, ACT_READ, "self", SRV_USER)
  
  #------------------------------------------------------------------------------#
  # create aother role
  Role.create(:id => ROL_DIR_ETB, :libelle => "Direction")
  Role.create(:id => ROL_CPE_ETB, :libelle => "CPE")
  Role.create(:id => ROL_AVS_ETB, :libelle => "Assistance vie scolaire")

  

  # Et les ActiviteRole
  

  #Role.create(:id => ROL_PROF_CLS, :libelle => "Professeur", :description => "Professeur enseignant dans une classe", :service_id => SRV_CLASSE)
  #Role.create(:id => ROL_PRFP_CLS, :libelle => "Professeur Principal", :description => "Professeur principal d'une classe", :service_id => SRV_CLASSE)
  #Role.create(:id => ROL_ELV_CLS, :libelle => "Elève", :service_id => SRV_CLASSE)

  #--------------------------------------------------------#
  # Profils utilisateurs with default role 
  # TODO: à modifier aussi
  # Les codes nationaux sont pris de la FAQ de l'annuaire ENT du SDET
  # http://eduscol.education.fr/cid57076/l-annuaire-ent-second-degre-et-son-alimentation-automatique.html

  Profil.create(:id => 'ELV', :description => 'Elève', :code_national => 'National_ELV', :role_id => ROL_ELV_ETB)
  Profil.create(:id => 'ETA', :description => 'Personnel administartif, technique ou d\'encadrement', :code_national => 'National_ETA', :role_id => ROL_PROF_ETB)
  Profil.create(:id => 'TUT', :description => "Responsable d'un élève", :code_national => 'National_TUT', :role_id => ROL_PAR_ETB) #role à revoir
  Profil.create(:id => 'DIR', :description => "Personel de direction de l'etablissement", :code_national => 'National_DIR', :role_id => ROL_DIR_ETB)
  Profil.create(:id => 'ENS', :description => 'Enseignant', :code_national => 'ENS', :code_national => 'National_ENS', :role_id => ROL_PROF_ETB)
  Profil.create(:id => 'EVS', :description => 'Personnel de vie scolaire', :code_national => 'National_EVS', :role_id => ROL_AVS_ETB)
  Profil.create(:id => 'ACA', :description => "Personnel de rectorat, DRAF, inspection", :code_national => 'National_ACA', :role_id => ROL_AVS_ETB)
  Profil.create(:id => 'DOC', :description => 'Documentaliste', :code_national => 'National_DOC', :role_id =>   ROL_PROF_ETB)
  Profil.create(:id => 'COL', :description => "Personnel de collectivité territoriale",  :code_national => 'National_COL', :role_id => ROL_CPE_ETB)
  #--------------------------------------------------------#
  
  # create root etablissement 
  e = Etablissement.create(:nom => "ERASME", :type_etablissement_id => 1, :code_uai => "0699999Z")
  # create super admin user  : role = TECH 
  u = User.create(:nom => "Saleh", :prenom => "Bashar", :sexe => "M", :login => "bsaleh", :password => "toortoor")
  RoleUser.create(:user_id => u.id, :etablissement_id => e.id, :role_id => ROL_TECH)
  ProfilUser.create(:user_id => u.id, :profil_id => 'COL', :etablissement_id => e.id)

  # create another supper admin user
  u2 = User.create(:nom => "Levallois", :prenom => "Pierre-Gille", :sexe => "M", :login => "plevallois", :password => "toortoor")
  RoleUser.create(:user_id => u2.id, :etablissement_id => e.id, :role_id => ROL_TECH)
  ProfilUser.create(:user_id => u.id, :profil_id => 'COL', :etablissement_id => e.id)

  u3 = User.create(:nom => "Le Moine", :prenom => "Gwenhael", :sexe => "M", :login => "gwenhael", :password => "suicyco")
  ProfilUser.create(:user_id => u3.id, :profil_id => 'COL', :etablissement_id => e.id)
  
  #
  #Tout d'abord on  a creé des applications
  #Application blog
  # panel_id = 'adm_pnl'
  # Service.create(:id => 'adm_pnl', :libelle => "Panel d'administration", :description => "Outil des gestion des utilisateurs de laclasse.com", :url => "/admin")
  # stat = Activite.create(:service_id => panel_id, :code => 'statistiques')
  # act = Activite.create(:service_id => panel_id, :code => 'activation_user')
  # gest = Activite.create(:service_id => panel_id, :code => 'gestion_user')
  # param = Activite.create(:service_id => panel_id, :code => 'param_app')

  # adm = Role.create(:libelle => 'Administrateur technique', :service_id => panel_id)
  # com = Role.create(:libelle => 'Chargé de communication', :service_id => panel_id)
  # assist = Role.create(:libelle => 'Assistance utilisateur', :service_id => panel_id)
  # activ_cmpt = Role.create(:libelle => 'Activateur compte', :service_id => panel_id)

  # DB[:role_profil].insert(:profil_id => 'TECH', :role_id => adm)
  # DB[:role_profil].insert(:profil_id => 'DIR', :role_id => com)
  # DB[:role_profil].insert(:profil_id => 'ADM', :role_id => assist)
  # DB[:role_profil].insert(:profil_id => 'AED', :role_id => activ_cmpt)

  # ActiviteRole.create(:activite_id => stat, :role_id => adm)
  # ActiviteRole.create(:activite_id => act, :role_id => adm)
  # ActiviteRole.create(:activite_id => gest, :role_id => adm)
  # ActiviteRole.create(:activite_id => param, :role_id => adm)

  # ActiviteRole.create(:activite_id => stat, :role_id => com)

  # ActiviteRole.create(:activite_id => stat, :role_id => assist)
  # ActiviteRole.create(:activite_id => gest, :role_id => assist)
  # ActiviteRole.create(:activite_id => act, :role_id => assist)

  # ActiviteRole.create(:activite_id => act, :role_id => activ_cmpt)

  # blog_id = 'blog'
  # Service.create(:id => 'blog', :libelle => 'Blog', :description => 'Outil de gestion de blog similaire à Wordpress', :url => '/blogs')
  # Activite.create(:libelle => 'ecrire_article', :service_id => blog_id)
  # Activite.create(:libelle => 'poster_commentaire', :service_id => blog_id)
  # Activite.create(:libelle => 'gerer_articles', :service_id => blog_id)
  # Activite.create(:libelle => 'lire_article', :service_id => blog_id)

  # Role.create(:libelle => 'Contributeur', :service_id => blog_id)
  # Role.create(:libelle => 'Lecteur', :service_id => blog_id)
  # Role.create(:libelle => 'Redacteur', :service_id => blog_id)

  # #Application cahier de texte
  # ct_id = 'ctexte'
  # Service.create(:id => ct_id,:libelle => 'Cahier de texte', :description => 'Outil de gestion des cahiers de texte', :url => '/ct')
  # Activite.create(:code => 'ecrire_devoir', :libelle => 'Ecrire devoir', :service_id => ct_id)
  # Activite.create(:code => 'lire_devoir', :libelle => 'Lire devoir', :service_id => ct_id)
  # Activite.create(:code => 'viser_cahier', :libelle => 'Viser cahier', :service_id => ct_id)
  # Activite.create(:code => 'supprimer_devoir', :libelle => 'Supprimer devoir', :service_id => ct_id)

  # role_prof_id = Role.create(:libelle => 'Prof', :service_id => ct_id)
  # role_eleve_id = Role.create(:libelle => 'Eleve', :service_id => ct_id)
  # role_principal_id = Role.create(:libelle => 'Principal', :service_id => ct_id)

  #create_super_admin_and_ressource_laclasse()


  #etb1 = Etablissement.create(:code_uai => '0691670R', :nom => 'Victor Dolto', :type_etablissement_id =>type_etb.id)
  #etb2 = Etablissement.create(:code_uai => '0690016T', :nom => 'Françoise Kandelaft', :type_etablissement_id =>type_etb.id)

  #--------------------------------------------------------------------------#
  # Ajouter des  parametres de test
  # d'abord on ajoute les param_type (text, num, bool)
  TypeParam.create(:id => TYP_PARAM_TEXT)
  TypeParam.create(:id => TYP_PARAM_BOOL)
  TypeParam.create(:id => TYP_PARAM_NUMBER)
  TypeParam.create(:id => TYP_PARAM_MSEL)
  TypeParam.create(:id => TYP_PARAM_USEL)
  
  #---------------------------------------------------------------------------#

  # deuxiement on ajoute les parametre  de test
  # DB[:param_app].insert(:preference => 0, :libelle => "Ouverture / Fermenture de l'ENT", :description => "Restreindre l'accès à l'ENT aux parents et aux élèves. Cette restriction est utile avant la rentrée scolaire, pendant la période de constitution des classes et des groupes. Elle prend effet dès que vous l'avez activée et prend fin lorsque vous la désactivez.",
  #                       :code => "ent_ouvert", :valeur_defaut => "oui", :autres_valeurs => "non", :service_id => 1 , :type_param_id=>"bool")
  # DB[:param_app].insert(:preference => 0, :libelle => "Réglage du seuil d'obtention du diplôme", :description => "Ce paramètre est fixé à 80% et détermine le seuil, en pourcentage du nombre de compétences à acquérir, à partir duquel les élèves obtiennent le diplôme du SOCLE.
  #                       Ce paramètre n'est pas modifiable.", :code => "seuil_obtention_diplome", :valeur_defaut => "80", :autres_valeurs => "50", :service_id => 1 , :type_param_id=>"num")
  # DB[:param_app].insert(:preference => 0, :libelle => "Ip Adresse", :description => "ip adresse de l'application",
  #                       :code => "adresse_ip", :valeur_defaut => "http://server1.com", :autres_valeurs => "http://server2.com", :service_id => 1 , :type_param_id=>"text")
end
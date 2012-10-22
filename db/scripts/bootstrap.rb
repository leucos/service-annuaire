#!ruby
#encoding: utf-8
require 'sequel'
require_relative '../../config/database'
require_relative '../../model/init'
require_relative 'bcn_parser'

##
## ATTENTION : A NE SURTOUT PAS UTILISER EN PRODUCTION
## SUPPRIME TOUTE LA BDD !!!!!!!
##
def clean_annuaire()
  puts "TRUNCATE ALL USER RELATED TABLES"
  [
    :last_uid, :telephone, :email, :relation_eleve,
    :enseigne_regroupement, :user, :regroupement, :ressource, :role_user
  ].each do |table|
    DB[table].truncate()
  end

  #Création de la ressource laclasse
  r = Ressource.create(:id_externe => 0, :service_id => SRV_LACLASSE)
  #Création du compte super admin
  u = User.create(:nom => "Super", :prenom => "Didier", :sexe => "M", :login => "root", :password => "root")
  RoleUser.unrestrict_primary_key()
  RoleUser.create(:user_id => u.id, :ressource_id => r.id, :role_id => ROL_TECH, :actif => true)

end

def bootstrap_annuaire()
  puts "TRUNCATE ALL TABLES"
  #On ne peut pas faire un bete DB.tables.each car il faut respecter l'ordre des foreign keys
  [
  :last_uid, :activite_role, :role_user, :activite, :role, :param_service, :type_param, :ressource, :service, :email,
  :telephone, :etablissement, :enseigne_regroupement, :regroupement,
  :user, :type_telephone, :type_regroupement, :type_relation_eleve, :profil, :niveau, :relation_eleve
  ].each do |table|
    DB[table].truncate()
  end

  puts "INSERT DEFAULT DATA"
  #Données temporaires
  Niveau.create(:libelle => "6EME")
  Niveau.create(:libelle => "5EME")
  Niveau.create(:libelle => "4EME")
  Niveau.create(:libelle => "3EME")

  TypeTelephone.unrestrict_primary_key()
  TypeTelephone.create(:id => TYP_TEL_MAIS, :libelle => 'Maison')
  TypeTelephone.create(:id => TYP_TEL_PORT, :libelle => 'Portable')
  TypeTelephone.create(:id => TYP_TEL_TRAV, :libelle => 'Travail')
  TypeTelephone.create(:id => TYP_TEL_AUTR, :libelle => 'Autre')

  TypeRelationEleve.unrestrict_primary_key()
  TypeRelationEleve.create(:id => TYP_REL_PAR, :libelle => 'Parent')
  # Si ENTEleveParents != ENTEleveAutoriteParentale ca veut dire qu'on a des parents sans autorité parentale
  TypeRelationEleve.create(:id => TYP_REL_NPAR, :libelle => 'Parent sans autorité parentale')
  TypeRelationEleve.create(:id => TYP_REL_RLGL, :libelle => 'Représentant légal')
  TypeRelationEleve.create(:id => TYP_REL_FINA, :libelle => 'Resp. financier')
  TypeRelationEleve.create(:id => TYP_REL_CORR, :libelle => 'Correspondant')


  TypeRegroupement.unrestrict_primary_key()
  TypeRegroupement.create(:id => TYP_REG_CLS, :libelle => 'Classe')
  TypeRegroupement.create(:id => TYP_REG_GRP, :libelle => "Groupe d'élèves")
  TypeRegroupement.create(:id => TYP_REG_LBR, :libelle => "Groupe libre")


  Service.unrestrict_primary_key()
  #Tout d'abord, on créer des services (api)
  # service laclasse.com (les super admin y sont reliés)
  Service.create(:id => SRV_LACLASSE, :libelle => "Laclasse.com", :description => "Service auquel tout est rattaché", :url => "/", :api => true)
  # laclasse est un ressource un peu spéciale car elle ne correspond pas a quelque chose en mémoire
  # on met comme id_externe 0
  ressource_laclasse = Ressource.create(:id_externe => 0, :service_id => SRV_LACLASSE)
  Role.unrestrict_primary_key()
  # Création des roles associés à ce service
  Role.create(:id => ROL_TECH, :libelle => "Administrateur technique", :service_id => SRV_LACLASSE)

  #
  # service /user
  #
  Service.create(:id => SRV_USER, :libelle => "Gestion utilisateur", :description => "Service de gestion des utilisateurs de laclasse.com", :url => "/user", :api => true)

  #
  # service /etablissement
  #
  Service.create(:id => SRV_ETAB, :libelle => "Gestion etablissement", :description => "Service de gestion des etablissements de laclasse.com", :url => "/etablissement", :api => true)

  #Création des rôles associés à ce service
  Role.create(:id => ROL_PROF_ETB, :libelle => "Professeur", :service_id => SRV_ETAB)
  Role.create(:id => ROL_ELV_ETB, :libelle => "Elève", :service_id => SRV_ETAB)
  Role.create(:id => ROL_ADM_ETB, :libelle => "Administrateur d'établissement", :service_id => SRV_ETAB)
  Role.create(:id => ROL_PAR_ETB, :libelle => "Parent", :service_id => SRV_ETAB)
  Role.create(:id => ROL_DIR_ETB, :libelle => "Principal", :service_id => SRV_ETAB)
  Role.create(:id => ROL_CPE_ETB, :libelle => "CPE", :service_id => SRV_ETAB)
  Role.create(:id => ROL_BUR_ETB, :libelle => "Personnel administratif", :service_id => SRV_ETAB)

  #
  # service /classe
  #
  Service.create(:id => SRV_CLASSE, :libelle => "Service de gestion des classes", :url => "/classe", :api => true)

  Role.create(:id => ROL_PROF_CLS, :libelle => "Professeur", :description => "Professeur enseignant dans une classe", :service_id => SRV_CLASSE)
  Role.create(:id => ROL_PRFP_CLS, :libelle => "Professeur Principal", :description => "Professeur principal d'une classe", :service_id => SRV_CLASSE)
  Role.create(:id => ROL_ELV_CLS, :libelle => "Elève", :service_id => SRV_CLASSE)

  # service /groupe

  # service /libre

  # service /rights

  # service /alimentation

  # service /preference ?


  #Profils utilisateurs
  # Les codes nationaux sont pris de la FAQ de l'annuaire ENT du SDET
  # http://eduscol.education.fr/cid57076/l-annuaire-ent-second-degre-et-son-alimentation-automatique.html
  Profil.unrestrict_primary_key()
  Profil.create(:id => 'ELV', :libelle => 'Elève', :code_national => 'National_1', :role_id => ROL_ELV_ETB)
  Profil.create(:id => 'ADM', :libelle => 'Administrateur Etablissement', :code_national => 'National_3', :role_id => ROL_ADM_ETB)
  Profil.create(:id => 'PAR', :libelle => 'Parent', :code_national => 'National_2', :role_id => ROL_PAR_ETB)
  Profil.create(:id => 'DIR', :libelle => 'Principal', :code_men => 'DIR', :code_national => 'National_4', :role_id => ROL_DIR_ETB)
  Profil.create(:id => 'ENS', :libelle => 'Professeur', :code_men => 'ENS', :code_national => 'National_3', :role_id => ROL_PROF_ETB)
  Profil.create(:id => 'ADF', :libelle => 'Personnels administratifs', :code_men => 'ADF', :code_national => 'National_6', :role_id => ROL_BUR_ETB)
  Profil.create(:id => 'ORI', :libelle => "Conseiller(ère) d'orientation", :code_men => 'ORI', :code_national => 'National_5', :role_id => ROL_BUR_ETB)
  Profil.create(:id => 'DOC', :libelle => 'Documentaliste', :code_men => 'DOC', :code_national => 'National_6', :role_id => ROL_PROF_ETB)
  Profil.create(:id => 'EDU', :libelle => "Conseiller(ère) d'éducation", :code_men => 'EDU', :code_national => 'National_5', :role_id => ROL_CPE_ETB)
  Profil.create(:id => 'OUV', :libelle => "Personnels ouvriers et de service", :code_men => 'OUV', :code_national => 'National_6', :role_id => ROL_BUR_ETB)
  Profil.create(:id => 'MDS', :libelle => "Personnels médico-sociaux", :code_men => 'MDS', :code_national => 'National_6', :role_id => ROL_BUR_ETB)
  Profil.create(:id => 'AED', :libelle => "Assistant(e) d'éducation", :code_men => 'AED', :code_national => 'National_5', :role_id => ROL_CPE_ETB)

  #Tout d'abord on créer des applications
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

  # ActiviteRole.unrestrict_primary_key()
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


  bootstrap_matiere()

  type_etb = TypeEtablissement.create({:nom => 'Service du département', :type_contrat => 'PU'})
  erasme_id = Etablissement.create(:nom => 'ERASME', :type_etablissement_id =>type_etb.id)

  #Des établissements
  #Les id d'établissement correspondent à des vrais identifiant pour tester l'alimentation automatique
  type_etb = TypeEtablissement.create(:nom => 'Collège', :type_contrat => 'PU', :libelle => 'Collège publique')
  etb1_id = Etablissement.create(:code_uai => '0691670R', :nom => 'Victor Dolto', :type_etablissement_id =>type_etb.id)
  etb2_id = Etablissement.create(:code_uai => '0690016T', :nom => 'Françoise Kandelaft', :type_etablissement_id =>type_etb.id)


  #Création du compte super admin
  u = User.create(:nom => "Super", :prenom => "Didier", :sexe => "M", :login => "root", :password => "root")
  RoleUser.unrestrict_primary_key()
  RoleUser.create(:user_id => u.id, :ressource_id => ressource_laclasse.id, :role_id => ROL_TECH, :actif => true)

  # Ajouter des  parametres de test
  # d'abord on ajoute les param_type (text, num, bool)
  TypeParam.unrestrict_primary_key()
  TypeParam.create(:id => "text")
  TypeParam.create(:id => "bool")
  TypeParam.create(:id => "num")
  # deuxiement on ajoute les parametre  de test
  # DB[:param_app].insert(:preference => 0, :libelle => "Ouverture / Fermenture de l'ENT", :description => "Restreindre l'accès à l'ENT aux parents et aux élèves. Cette restriction est utile avant la rentrée scolaire, pendant la période de constitution des classes et des groupes. Elle prend effet dès que vous l'avez activée et prend fin lorsque vous la désactivez.",
  #                       :code => "ent_ouvert", :valeur_defaut => "oui", :autres_valeurs => "non", :service_id => 1 , :type_param_id=>"bool")
  # DB[:param_app].insert(:preference => 0, :libelle => "Réglage du seuil d'obtention du diplôme", :description => "Ce paramètre est fixé à 80% et détermine le seuil, en pourcentage du nombre de compétences à acquérir, à partir duquel les élèves obtiennent le diplôme du SOCLE.
  #                       Ce paramètre n'est pas modifiable.", :code => "seuil_obtention_diplome", :valeur_defaut => "80", :autres_valeurs => "50", :service_id => 1 , :type_param_id=>"num")
  # DB[:param_app].insert(:preference => 0, :libelle => "Ip Adresse", :description => "ip adresse de l'application",
  #                       :code => "adresse_ip", :valeur_defaut => "http://server1.com", :autres_valeurs => "http://server2.com", :service_id => 1 , :type_param_id=>"text")


  profil_list = ['ENS', 'ELV', 'PAR']

  prenom_list = ['jean', 'francois', 'raymond', 'pierre', 'jeanne', 'frédéric', 'lise', 'michel', 'daniel', 'élodie', 'brigitte', 'béatrice', 'youcef', 'sophie', 'andréas']
  nom_list = ['dupond', 'dupont', 'duchamp', 'deschamps', 'leroy', 'lacroix', 'sarkozy', 'zidane', 'bruni', 'hollande', 'levy', 'khadafi', 'chirac']

  RelationEleve.unrestrict_primary_key()
  #On va créer pour chaque établissement 100 utilisateurs
  2.times do |nb|
    etb_id = nb == 0 ? etb1_id : etb2_id
    100.times do |ind|
      #Création aléatoire d'un nom et d'un utilisateur
      r = Random.new
      pren = prenom_list[r.rand(prenom_list.length)]
      nom = nom_list[r.rand(nom_list.length)]
      sexe = r.rand(2) == 0 ? "M" : "F"
      #On essait de rendre le login unique avec 1ere lettre prenom + nom + un chiffre aléatoire
      #Y a mieux mais on s'en fou

      login = User.find_available_login(pren, nom)
      #Password = login
      usr = User.create(:login => login, :password => login, :nom => nom, :prenom => pren, :sexe => sexe)
      #Les profil sont choisit aléatoirement
      profil = profil_list[r.rand(profil_list.length)]
      #Sauf qu'on a un principal par etab
      if ind == 0
        profil = "DIR"
      #Et un admin d'étab
      elsif ind == 1
        profil = "ADM"
      elsif profil == "ELV"
        # On donne des identifiants sconet aux eleves
        usr.id_sconet = r.rand(1000000)
        while User[:id_sconet => usr.id_sconet] != nil
          usr.id_sconet = r.rand(1000000)
        end
        usr.save
      elsif profil == "PAR"
        # On rajoute une relation
        # Soit parent, soit representant legal
        rel = r.rand(2) > 0 ? "PAR" : "RLGL"
        #On prend le premier eleve qui n'a pas cette relation
        eleve = User.
          left_join(:relation_eleve, :eleve_id => :id).
          filter(:profil_user => ProfilUser.filter(:profil_id => "ELV")).
          filter({:type_relation_eleve_id => nil}).first
        if eleve
          RelationEleve.create(:user_id => usr.id, :eleve_id => eleve.id, :type_relation_eleve_id => rel)
        end
      end
      role_id = Profil[profil].role_id
      # Temp ne marche pas pour l'instant
      #res_etb = Ressource.filter(:service_id => SRV_ETAB, :id_externe => etb_id).first
      #RoleUser.create(:user_id => usr.id, :ressource_id => res_etb.id, :role_id => role_id, :actif => true)
    end
  end
end
#!ruby
#encoding: utf-8
require 'sequel'
require_relative '../../config/database'
require_relative '../../model/user'
require_relative 'bcn_parser'

##
## ATTENTION : A NE SURTOUT PAS UTILISER EN PRODUCTION
## SUPPRIME TOUTE LA BDD !!!!!!!
##
def clean_annuaire()
  puts "TRUNCATE ALL USER RELATED TABLES"
  [
    :last_uid, :profil_user, :telephone, :email, :relation_eleve, :membre_regroupement,
    :enseigne_regroupement, :user, :regroupement
  ].each do |table|
    DB[table].truncate()
  end

  #Création du compte super admin
  u = User.create(:nom => "Super", :prenom => "Didier", :sexe => "M", :login => "root", :password => "root")
  DB[:profil_user].insert(:user_id => u.id, :etablissement_id => Etablissement.first.id, :profil_id => 'TECH', :actif => true)

end

def bootstrap_annuaire()
  puts "TRUNCATE ALL TABLES"
  #On ne peut pas faire un bete DB.tables.each car il faut respecter l'ordre des foreign keys
  [
  :last_uid, :activite_role, :role_user, :role_profil, :activite, :role, :param_app, :type_param, :app, :email,
  :profil_user, :telephone, :etablissement, :membre_regroupement, :enseigne_regroupement, :regroupement,
  :user, :type_telephone, :type_regroupement, :type_relation_eleve, :profil, :niveau, :relation_eleve
  ].each do |table|
    DB[table].truncate()
  end

  puts "INSERT DEFAULT DATA"
  #Données temporaires
  DB[:niveau].insert(:libelle => "6EME")
  DB[:niveau].insert(:libelle => "5EME")
  DB[:niveau].insert(:libelle => "4EME")
  DB[:niveau].insert(:libelle => "3EME")

  DB[:type_telephone].insert(:id => 'MAIS', :libelle => 'Maison')
  DB[:type_telephone].insert(:id => 'PORT', :libelle => 'Portable')
  DB[:type_telephone].insert(:id => 'TRAV', :libelle => 'Travail')
  DB[:type_telephone].insert(:id => 'AUTR', :libelle => 'Autre')

  DB[:type_relation_eleve].insert(:id => 'PAR', :libelle => 'Parent')
  DB[:type_relation_eleve].insert(:id => 'RLGL', :libelle => 'Représentant légal')
  DB[:type_relation_eleve].insert(:id => 'FINA', :libelle => 'Resp. financier')
  DB[:type_relation_eleve].insert(:id => 'CORR', :libelle => 'Correspondant')


  DB[:type_regroupement].insert(:id => 'CLS', :libelle => 'Classe')
  DB[:type_regroupement].insert(:id => 'GRP', :libelle => "Groupe d'élèves")
  DB[:type_regroupement].insert(:id => 'LBR', :libelle => "Groupe libre")

  #Profils utilisateurs
  # Les codes nationaux sont pris de la FAQ de l'annuaire ENT du SDET
  # http://eduscol.education.fr/cid57076/l-annuaire-ent-second-degre-et-son-alimentation-automatique.html
  DB[:profil].insert(:id => 'ELV', :libelle => 'Elève', :code_national => 'National_1')
  DB[:profil].insert(:id => 'ADM', :libelle => 'Administrateur Etablissement', :code_national => 'National_3')
  DB[:profil].insert(:id => 'TECH', :libelle => 'Administrateur technique', :code_national => 'National_3')
  DB[:profil].insert(:id => 'PAR', :libelle => 'Parent', :code_national => 'National_2')
  DB[:profil].insert(:id => 'DIR', :libelle => 'Principal', :code_men => 'DIR', :code_national => 'National_4')
  DB[:profil].insert(:id => 'ENS', :libelle => 'Professeur', :code_men => 'ENS', :code_national => 'National_3')
  DB[:profil].insert(:id => 'ADF', :libelle => 'Personnels administratifs', :code_men => 'ADF', :code_national => 'National_6')
  DB[:profil].insert(:id => 'ORI', :libelle => "Conseiller(ère) d'orientation", :code_men => 'ORI', :code_national => 'National_5')
  DB[:profil].insert(:id => 'DOC', :libelle => 'Documentaliste', :code_men => 'DOC', :code_national => 'National_6')
  DB[:profil].insert(:id => 'EDU', :libelle => "Conseiller(ère) d'éducation", :code_men => 'EDU', :code_national => 'National_5')
  DB[:profil].insert(:id => 'OUV', :libelle => "Personnels ouvriers et de service", :code_men => 'OUV', :code_national => 'National_6')
  DB[:profil].insert(:id => 'MDS', :libelle => "Personnels médico-sociaux", :code_men => 'MDS', :code_national => 'National_6')
  DB[:profil].insert(:id => 'AED', :libelle => "Assistant(e) d'éducation", :code_men => 'AED', :code_national => 'National_5')


  #Tout d'abord on créer des applications
  #Application blog
  panel_id = DB[:app].insert(:code => 'admin_panel', :libelle => "Panel d'administration", :description => "Outil des gestion des utilisateurs de laclasse.com", :url => "/admin")
  stat = DB[:activite].insert(:app_id => panel_id, :code => 'statistiques')
  act = DB[:activite].insert(:app_id => panel_id, :code => 'activation_user')
  gest = DB[:activite].insert(:app_id => panel_id, :code => 'gestion_user')
  param = DB[:activite].insert(:app_id => panel_id, :code => 'param_app')

  adm = DB[:role].insert(:libelle => 'Administrateur technique', :app_id => panel_id)
  com = DB[:role].insert(:libelle => 'Chargé de communication', :app_id => panel_id)
  assist = DB[:role].insert(:libelle => 'Assistance utilisateur', :app_id => panel_id)
  activ_cmpt = DB[:role].insert(:libelle => 'Activateur compte', :app_id => panel_id)

  DB[:role_profil].insert(:profil_id => 'TECH', :role_id => adm)
  DB[:role_profil].insert(:profil_id => 'DIR', :role_id => com)
  DB[:role_profil].insert(:profil_id => 'ADM', :role_id => assist)
  DB[:role_profil].insert(:profil_id => 'AED', :role_id => activ_cmpt)

  DB[:activite_role].insert(:activite_id => stat, :role_id => adm)
  DB[:activite_role].insert(:activite_id => act, :role_id => adm)
  DB[:activite_role].insert(:activite_id => gest, :role_id => adm)
  DB[:activite_role].insert(:activite_id => param, :role_id => adm)

  DB[:activite_role].insert(:activite_id => stat, :role_id => com)

  DB[:activite_role].insert(:activite_id => stat, :role_id => assist)
  DB[:activite_role].insert(:activite_id => gest, :role_id => assist)
  DB[:activite_role].insert(:activite_id => act, :role_id => assist)

  DB[:activite_role].insert(:activite_id => act, :role_id => activ_cmpt)

  blog_id = DB[:app].insert(:libelle => 'Blog', :code => 'blog', :description => 'Outil de gestion de blog similaire à Wordpress', :url => '/blogs')
  DB[:activite].insert(:libelle => 'ecrire_article', :app_id => blog_id)
  DB[:activite].insert(:libelle => 'poster_commentaire', :app_id => blog_id)
  DB[:activite].insert(:libelle => 'gerer_articles', :app_id => blog_id)
  DB[:activite].insert(:libelle => 'lire_article', :app_id => blog_id)

  DB[:role].insert(:libelle => 'Contributeur', :app_id => blog_id)
  DB[:role].insert(:libelle => 'Lecteur', :app_id => blog_id)
  DB[:role].insert(:libelle => 'Redacteur', :app_id => blog_id)

  #Application cahier de texte
  ct_id = DB[:app].insert(:libelle => 'Cahier de texte', :code => 'cahier_texte', :description => 'Outil de gestion des cahiers de texte', :url => '/ct')
  DB[:activite].insert(:code => 'ecrire_devoir', :libelle => 'Ecrire devoir', :app_id => ct_id)
  DB[:activite].insert(:code => 'lire_devoir', :libelle => 'Lire devoir', :app_id => ct_id)
  DB[:activite].insert(:code => 'viser_cahier', :libelle => 'Viser cahier', :app_id => ct_id)
  DB[:activite].insert(:code => 'supprimer_devoir', :libelle => 'Supprimer devoir', :app_id => ct_id)

  role_prof_id = DB[:role].insert(:libelle => 'Prof', :app_id => ct_id)
  role_eleve_id = DB[:role].insert(:libelle => 'Eleve', :app_id => ct_id)
  role_principal_id = DB[:role].insert(:libelle => 'Principal', :app_id => ct_id)

  DB[:role_profil].insert(:profil_id => 'ELV', :role_id => role_eleve_id)
  DB[:role_profil].insert(:profil_id => 'ENS', :role_id => role_prof_id)
  DB[:role_profil].insert(:profil_id => 'DIR', :role_id => role_principal_id)

  bootstrap_matiere()

  type_etb_id = DB[:type_etablissement].insert({:nom => 'Service du département', :type_contrat => 'PU'})
  erasme_id = DB[:etablissement].insert(:nom => 'ERASME', :type_etablissement_id =>type_etb_id)

  #Des établissements
  #Les id d'établissement correspondent à des vrais identifiant pour tester l'alimentation automatique
  type_etb_id = DB[:type_etablissement].insert(:nom => 'Collège', :type_contrat => 'PU', :libelle => 'Collège publique')
  etb1_id = DB[:etablissement].insert(:code_uai => '0691670R', :nom => 'Victor Dolto', :type_etablissement_id =>type_etb_id)
  etb2_id = DB[:etablissement].insert(:code_uai => '0690016T', :nom => 'Françoise Kandelaft', :type_etablissement_id =>type_etb_id)


  #Création du compte super admin
  u = User.create(:nom => "Super", :prenom => "Didier", :sexe => "M", :login => "root", :password => "root")
  DB[:profil_user].insert(:user_id => u.id, :etablissement_id => erasme_id, :profil_id => 'TECH', :actif => true)

  # Ajouter des  parametres de test
  # d'abord on ajoute les param_type (text, num, bool)
  DB[:type_param].insert(:id => "text")
  DB[:type_param].insert(:id => "bool")
  DB[:type_param].insert(:id => "num")
  # deuxiement on ajoute les parametre  de test
  DB[:param_app].insert(:preference => 0, :libelle => "Ouverture / Fermenture de l'ENT", :description => "Restreindre l'accès à l'ENT aux parents et aux élèves. Cette restriction est utile avant la rentrée scolaire, pendant la période de constitution des classes et des groupes. Elle prend effet dès que vous l'avez activée et prend fin lorsque vous la désactivez.",
                        :code => "ent_ouvert", :valeur_defaut => "oui", :autres_valeurs => "non", :app_id => 1 , :type_param_id=>"bool")
  DB[:param_app].insert(:preference => 0, :libelle => "Réglage du seuil d'obtention du diplôme", :description => "Ce paramètre est fixé à 80% et détermine le seuil, en pourcentage du nombre de compétences à acquérir, à partir duquel les élèves obtiennent le diplôme du SOCLE.
                        Ce paramètre n'est pas modifiable.", :code => "seuil_obtention_diplome", :valeur_defaut => "80", :autres_valeurs => "50", :app_id => 1 , :type_param_id=>"num")
  DB[:param_app].insert(:preference => 0, :libelle => "Ip Adresse", :description => "ip adresse de l'application",
                        :code => "adresse_ip", :valeur_defaut => "http://server1.com", :autres_valeurs => "http://server2.com", :app_id => 1 , :type_param_id=>"text")


  profil_list = ['ENS', 'ELV', 'PAR']

  prenom_list = ['jean', 'francois', 'raymond', 'pierre', 'jeanne', 'frédéric', 'lise', 'michel', 'daniel', 'élodie', 'brigitte', 'béatrice', 'youcef', 'sophie', 'andréas']
  nom_list = ['dupond', 'dupont', 'duchamp', 'deschamps', 'leroy', 'lacroix', 'sarkozy', 'zidane', 'bruni', 'hollande', 'levy', 'khadafi', 'chirac']

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
          DB[:relation_eleve].insert(:user_id => usr.id, :eleve_id => eleve.id, :type_relation_eleve_id => rel)
        end
      end
      DB[:profil_user].insert(:user_id => usr.id, :etablissement_id => etb_id, :profil_id => profil, :actif => true)
    end
  end
end
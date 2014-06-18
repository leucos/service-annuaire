service-annuaire
================

ATTENTION : CE PROJET COMMENCE A PEINE ET N'EST PAS DU TOUT A UN STADE UTILISABLE. LES SOURCES SONT DISPONIBLES A TITRE INFORMATIF. BEAUCOUP DE CHOSES SONT ENCORE AMENEES A BOUGER DANS LA STRUCTURE DES DONNEES ET L'API UTILISATEUR.

Ensemble de services web (REST) pour manipuler les données d'annuaire dans laclasse.com

## Configuration
    export NLS_LANG=FRENCH_FRANCE.UTF8
    bundle install
    bundle exec rake db:configure
    modifier les configurations dans le dossier /config/ si besoin

## bootstrap database
	create database annuairev3 in mysql
    mysql -u user -p password < annuaire_create.sql
    bundle exec rake db:bootstrap
    
puis utiliser les service de l'alimentation pour alimenter les matieres, fonctions, code_mefs

 **note: api_key is configured in config/auth.rb **
 
    annuaire_server/api/alimentation/sync_mat?api_key="secret"
    annuaire_server/api/alimentation/sync_fonc?api_key="secret"
    annuaire_server/api/alimentation/sync_mef?api_key="secret"
  
### Dans le cas d'utilisation d'oracle "supprimé"
    bundle exec rake db:configure_oracle
    bundle exec rake db:bootstrap
    bundle exec rake db:bootstrap_matiere
    bundle exec rake spec

Si tous les tests passent, on est bon :).
Note : les tests ne passeront tous que si la base de donnée vient d'être "bootstrapée", si vous avez rajouté des utilisateurs, certains tests ne passeront pas.


## Documentation des APIs
  consulter le fichier doc_restfull_apis.md


## Documentation de l'authentification 
  consulter le fichier doc_authentification.md 

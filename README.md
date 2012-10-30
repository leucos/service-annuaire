service-annuaire
================

ATTENTION : CE PROJET COMMENCE A PEINE ET N'EST PAS DU TOUT A UN STADE UTILISABLE. LES SOURCES SONT DISPONIBLES A TITRE INFORMATIF. BEAUCOUP DE CHOSES SONT ENCORE AMENEES A BOUGER DANS LA STRUCTURE DES DONNEES ET L'API UTILISATEUR.


Ensemble de service web pour manipuler les données d'annuaire dans laclasse.com

# Documentation de l'API

ATTENTION, il ne s'agit pas forcément de l'api actuelle mais de ce que l'on aimerait avoir

## /user et /users

Permet de manipuler les utilisateurs ainsi que leur ressources associés (numéro de téléphone, adresse, email, rattachements?)

  <!-- open bar, sans cookie -->
  * GET /user?login=test&password=test
  res 200:
  { id: "vaa60001", ... }
  res 40x:
  { "code": 1, ... }

  // récupère le cookie ou l'id en param GET ou
  // une entête HTTP maison
  * GET /user/vaa6001
  res 200:
  { "id": "vaa60001", ... }

  // création d'un compte utilisateur. Nécessite les droits
  // admin ou une clef d'un autre service (via la conf)
  * POST /user
  { "login": "test", "password": "test", "prenom": "Toto" ...}
  res 200:
  { "id": ... }
  res 400: // infos insuffisantes
  { "code": 15, "message": ""}
  res 401: // pas les droits

  // suppression d'un utilisateur
  * DELETE /user/vaa60001
  res 200

  // modification d'un compte utilisateur
  * PUT /user
  { "prenom": "Toto", "password": "test2" }
  res 200:
  { "id": ... }

  // recherche les utilisateurs. Filtré par le compte
  // utilisateur en cours. Limite par défaut et limite max
  // en fonction du compte courant...
  * GET /users?query=toto+titi&limit=100&page=1&order=prenom&prenom=titi&etab=15
  res 200:
  { "users": [ { "id": , "" } ] }


  //Ajout de profils
  POST /user/:id/profils
  {profil_id: "ELV", etablissement_id: 1234}

  //Modification d'un profil
  POST /user/:id/profils
  {profil_id: "ELV", etablissement_id: 1234}

  DEL /user/:id/profils/
  {profil_id: "ELV", etablissement_id: 1234}

### La ressource "utilisateur":

  {
    "id": "vaa60001",
    "prenom": "Toto",
    "nom": "Titi",
    "login": "toto",
    "emails": [
      { "id": 12, "type": "academique", "email": "test@erasme.org" },
      { "id": 13, "type": "personnel", "email": "quiche@gmail.com" }
    ],
    "etablissements": [
      { "id": "BBBn",
        "nom": "St Didier",
        "profils": [ "prof", "parent" ]
      },
      {
        "id": "aaa",
        "nom": "Maurice",
        "profils": [ "parent" ]
      }
    ],
    "groupes": [
      {
        "id": ,
      "type": "classe",
        "etablissement": "tyu",
        "matieres": [ { "id": "", "nom": "Maths" } ]
        "nom": "quper",
        "profils": [ "admin", "prof_principale" ]
      
  }  ],
    "ressources": [
      {
        "id": ,
        "type": "calendrier",
        "data": "1234",
        "groupe": "23"
      }
    ]
  }// open bar, sans cookie
  GET /user?login=test&password=test
  res 200:
  { id: "vaa60001", ... }
  res 40x:
  { "code": 1, ... }

  // récupère le cookie ou l'id en param GET ou
  // une entête HTTP maison
  GET /user/vaa6001
  res 200:
  { "id": "vaa60001", ... }

  // création d'un compte utilisateur. Nécessite les droits
  // admin ou une clef d'un autre service (via la conf)
  POST /user
  { "login": "test", "password": "test", "prenom": "Toto" ...}
  res 200:
  { "id": ... }
  res 400: // infos insuffisantes
  { "code": 15, "message": ""}
  res 401: // pas les droits

  // suppression d'un utilisateur
  DELETE /user/vaa60001
  res 200

  // modification d'un compte utilisateur
  PUT /user
  { "prenom": "Toto", "password": "test2" }
  res 200:
  { "id": ... }

  // recherche les utilisateurs. Filtré par le compte
  // utilisateur en cours. Limite par défaut et limite max
  // en fonction du compte courant...
  GET /users?query=toto+titi&limit=100&page=1&order=prenom&prenom=titi&etab=15
  res 200:
  { "users": [ { "id": , "" } ] }


  //Ajout de profils
  POST /user/:id/profils
  {profil_id: "ELV", etablissement_id: 1234}

  //Modification d'un profil
  POST /user/:id/profils
  {profil_id: "ELV", etablissement_id: 1234}

  DEL /user/:id/profils/
  {profil_id: "ELV", etablissement_id: 1234}


## /etablissement

  // creer un etablissement
  POST /etablissement
  { "id": 1234, "nom": "Saint Honoré" }
  res 200:
  { "id":  ... }

  POST /etablissement/:id/role/:user_id
  {"role": "professeur"}

  GET /etablissement/:id/role/:user_id

  //Il faut aussi pouvoir récupérer quel role à le droit d'attribuer un utilisateur sur un établissement
  //Car on ne doit pas pouvoir attribuer un rôle de super admin si on est que admin_etb
  GET /etablissement/:id/attrib_role/:user_id
  ["professeur","admin_etb","eleve"]

  //Assigner un role à quelqu'un
  POST /etablissement/:id/role_user/:user_id
  {role_id : "ADM_ETB"}
  //Changer le role de quelqu'un
  PUT /etablissement/:id/role_user/:user_id
  {role_id : "PROF"}
  //Supprimer son role sur l'établissement
  DEL /etablissement/:id/role_user/:user_id

  //Interface similaire pour /classe, /groupe et /libre
  //Peut-être qu'on mettra tout ça dans /regroupement ?
  POST /etablissement/:id/classe
  {nom: "4°C", niveau: "4EME"}
  //Modification
  PUT /etablissement/:id/classe/:classe_id
  {nom: "4°D"}
  //Suppression du groupe
  DEL /etablissement/:id/classe/:classe_id
  //Gestion des rattachement et des roles
  POST /etablissement/:id/classe/:classe_id/role_user/:user_id
  {role_id : "PROF"}
  //Dettachement
  DEL /etablissement/:id/classe/:classe_id/role_user/:user_id
  //Seulement possible pour classe et groupe d'élève
  POST /etablissement/:id/classe/:classe_id/enseigne/:user_id
  {matieres : ["FRANCAIS", "MATHEMATIQUES"]}


  //Gestion des rattachements à un groupe libre
  //Comment faire pour gérer le fait qu'un élève à le droit de se rattacher à un groupe libre, mais 
  //pas de définir un role dessus à quelqu'un d'autre ?
  POST /etablissement/:id/libre/:libre_id/rattach
  DEL /etablissement/:id/libre/:libre_id/rattach

  //Récupérer les niveaux pour cet établissement
  GET /etablissement/:id/classe/niveaux

## /matiere
  //Permet de chercher une matière parmis les quelques 2600 fournient par la BCN
  GET /matiere/?query="Fran"&niveau="4EME"

## /libre (groupes libres)

  POST /libre
  { "nom": "Test groupe" }
  res 200:
  { "id" 456, "nom":... }
  regroupements
  PUT /regroupement/456/rights
  { user: ,  droit: "membre" }

  DELETE /regroupement/456/rights/vaa60001

  //Assigner un role à quelqu'un
  POST /etablissement/:id/role_user/:user_id
  {role_id : "ADM_REG"}
  //Changer le role de quelqu'un
  PUT /etablissement/:id/role_user/:user_id
  {role_id : "MEMBRE"}
  //Supprimer son role sur l'établissement
  DEL /etablissement/:id/role_user/:user_id

## /classe

  //Récupérer tous les niveaux possibles
  GET /classe/niveaux/
  ["CP",... "4EME"... "Terminale"]

## /alimentation

Le service d'alimentation est un peu spécial : il permet de gérer l'alimentation automatique (via l'académie) ou manuel (via upload de fichier) en comptes d'un établissement.
Il donne accès aux logs, à la configuration et à l'activation de ce service.
C'est un élément centrale de l'annuaire car il permet à un établissement de créer très rapidement un ensemble de compte (surtout avec l'alimentation automatique).

  //Envois de fichier d'alimentation dans la BDD
  POST /alimentation/:etablissement_id
  {type: "xml_menesr"} ?

  // Avant l'alimentation on peut manuellement recoller des utilisateurs qui n'ont pas été
  // recoller automatiquement
  POST /alimentation/recollement/:alimentation_id
  {"id_ent" : "VAA60000", "id_jointure_aaf" : 12345678}

  //Récupère les données "brutes" d'une alimentation en cours (pas encore appliquée)
  //Ou déjà effectuée
  GET /alimentation/data/:etablissement_id?alimentation_id=1234

  //Récupère les diffs d'une alimentation en cours (pas encore appliquée)
  //Ou déjà effectuée
  GET /alimentation/diff/:etablissement_id?alimentation_id=1234

  //Applique une alimentation dans la base de donnée
  POST /alimentation/apply/:alimentation_id

  //Active ou désactive l'alimentation automatique sur un établissement
  PUT /alimentation/state/:etablissement_id
  {enable: false}

  GET /alimentation/state/:etablissement_id

  //Récupère l'historique des alimentations d'un établissement
  //Pour le type manuel et/ou automatique
  GET /alimentation/histo/:etablissement_id?type=manuel
  {
    alimentation : [
      {
        id : 1,
        errors : 5,
        warnings : 2,
        date: '20120910',
        full: true, //Est-ce un delta ou une complete ?
        type: "auto",
        summary : "1 Suppression de compte, 3 modifications etc."
      },
      {
        id : 2,
        errors : 0,
        warnings : 1
        date: '20120908',
        full: false,
        type: "auto",
        summary : "Ajout de l'élève Machin"
      }
    ]
  }

## Preference

  GET /preference/:code


## rights

  //Droits sur une ressource précise
  GET /rights/:service_id/:ressource_id/:user_id
  [create_user, add_membre]

  //Droits sur un service en général (les services sont aussi des ressources)
  GET /rights/service/:service_id/:user_id

  //Renvois la liste des roles possible pour un service donné (open bar?)
  GET /rights/role/:service_id
  ["ADM_ETB", "PROF", "DIR", "ELEVE"]

## Gestion des rôles et des activités
  //Accessible qu'à un admin d'établissement
  //Création/suppression/modification de rôle
  POST /rights/role/
  {id : "ADM_ETB", libelle : "Administateur d'établissement", service_id : "ETAB"}
  PUT /rights/role/:id
  {libelle : "Admin. Etb."}
  DEL /rights/role/:id

  //Ajout/Suppression d'activité(s) à un role sur un service
  POST /rigths/activite_role
  {role_id : "ADM_ETB", service_id : "ETAB", activite_id : "CREATE_USER"}
  DEL /rigths/activite_role
  {role_id : "ADM_ETB", service_id : "ETAB", activite_id : "CREATE_USER"}

  //Ajout/suppression/edition d'activités
  POST /rights/activite
  {id: "CREATE_USER", libelle : "Création d'utilisateurs"}
  PUT /rights/activite/:id
  {description : "Cool"}
  DEL /rights/activite/:id

  //Associer/desassocier quelqu'un à un rôle sur une ressource
  POST /rights/role_user/:service_id/:ressource_id/:user_id
  {role_id : "ADM_ETB"}
  DEL /rights/role_user/:service_id/:ressource_id/:user_id
  {role_id : "ADM_ETB"}
##


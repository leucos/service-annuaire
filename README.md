service-annuaire
================

ATTENTION : CE PROJET COMMENCE A PEINE ET N'EST PAS DU TOUT A UN STADE UTILISABLE. LES SOURCES SONT DISPONIBLES A TITRE INFORMATIF. BEAUCOUP DE CHOSES SONT ENCORE AMENEES A BOUGER DANS LA STRUCTURE DES DONNEES ET L'API UTILISATEUR.


Ensemble de service web pour manipuler les données d'annuaire dans laclasse.com

# Configuration

  bundle install
  bundle exec rake db:configure
  bundle exec rake db:bootstrap
  bundle exec rake db:bootstrap_matiere
  bundle exec rake spec

Si tous les tests passent, on est bon :).

# Documentation de l'API

ATTENTION, il ne s'agit pas forcément de l'api actuelle mais de ce que l'on aimerait avoir

## Code d'erreur HTTP utilisés

//l'usage de 401 et 403 est inspiré de l'API google drive
400 => La syntaxe de la requète est mauvaise. Soit il manque des paramètres, soit le format des paramètres n'est pas valide (String à la place d'Integer ou Sql Validation failed)
401 => Ce service requiert une authentification et l'utilisateur n'est pas authentifié
403 => L'utilisateur est authentifié mais n'a pas les droits d'accéder à ce service
404 => La ressource n'est pas trouvée. La syntaxe de la requète est bonne mais les paramètres ne correspondent pas à une ressource existante (ex : user non existant) ou ne sont pas logique par rapport au path. Ex : l'email n'appartient pas à l'utilisateur dans /user/:user_id/email/:email_id
405 => Si le verbe HTTP utilisé pour un path n'existe pas (exemple appel de DELETE pour un url disponible uniquement en GET) et quand l'url n'existe pas.

## /user et /users

Permet de manipuler les utilisateurs ainsi que leur ressources associés (numéro de téléphone, adresse, email, rattachements?)

  `
  //TODO : gestion création de compte
  //Activation avec code
  //Gestion des rattachement à un autre fournisseur d'identité
  //Api pour savoir si un login est dispo ?
  GET /user/login_available?login=prout
  res : 200 avec message si OK, pas dispo ou pas valide ?
  //api pour tester si un mot de passe correspond au critère de validation des mots de passes ?
  
  //Il faut une api publique pour récupérer l'id d'un utilisateur en fonction de son login
  //ou d'un de ses emails
  //Envois un mail de régénération de mot de passe
  //Temporiser les appel pour éviter les spams ?
  GET /user/forgot_password?login=test&adresse=test@laclasse.com

  // open bar, sans cookie
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
  PUT /user
  { "prenom": "Toto", "password": "test2", telephone: {type: "MAIS", numero: "0412345678"} }
  res 200:
  { "id": ... }

  // recherche les utilisateurs. Filtré par le compte
  // utilisateur en cours. Limite par défaut et limite max
  // en fonction du compte courant...
  * GET /users?query=toto+titi&limit=100&page=1&order=prenom&prenom=titi&etab=15
  res 200:
  { "users": [ { "id": , "" } ] }


  //Récupération des relations
  GET /user/:user_id/relations

  //Ajout d'une relation entre un adulte et un élève
  //Il ne peut y en avoir qu'une part adulte
  POST /user/:user_id/relation
  //Cas d'un user qui devient parent d'élève
  {eleve_id: VAA60001, type_relation_id: "PAR"}

  //Modification de la relation
  PUT /user/:user_id/relation/:eleve_id
  {type_relation_id: "RLGL"}

  //Suppression de la relation (1 par adulte)
  DEL /user/:user_id/relation/:eleve_id

  //Email ?
  GET /user/:user_id/emails
  [{id: 1, adresse: "test@laclasse.com"},{id: 2, adresse: "test2@laclasse.com"}]
  POST /user/:user_id/email
  param : {adresse: "alivet@ac-lyon.fr", academique: true}
  res : {id: 1, adresse: "alivet@ac-lyon.fr", academique: true}
  PUT /user/:user_id/email/:email_id
  {adresse: "test@lyon.fr", type: "principal ou academique"}
  DELETE /user/:user_id/email/:email_id
  //Envois un email de validation pour vérifier si l'adresse est valide
  //Stocker ça dans Redis et mettre un ttl de 1h ou 6h
  //Doit-on appeler ca de la validation ou de la vérification ?
  GET /user/:user_id/email/:email_id/validate
  //On peut mettre aussi request_validation et confirm_validation comme github
  //La clé à été envoyée par mail
  GET /user/:user_id/email/:email_id/validate/:validation_key


  //Telephone
  GET /user/:user_id/telephones
  [{id: 1, numero: "0472541212", type_telephone_id: "MAIS"}]
  POST /user/:user_id/telephone
  param : {numero: "0472548989"}
  res: {id: 1, numero: "0472548989", type_telephone_id: "MAIS"}
  DELETE /user/:user_id/telephone/:telephone_id

  //Récupère les préférences d'une application
  GET /user/:user_id/application/application_id/preferences
  //Modifie une préférence
  PUT /user/:user_id/application/application_id/preferences
  {"show_toolbar":true}
  //Remettre la valeure par défaut de la préférence
  PUT /user/:user_id/application/application_id/preferences
  {"show_toolbar":null}
  //Remettre la valeure par défaut pour toutes les préférences
  DEL /user/:user_id/application/application_id/preferences
  `

### La ressource "utilisateur":

  `
  {
    "id": "vaa60001",
    "prenom": "Toto",
    "nom": "Titi",
    "login": "toto",
    "adresse_emails": [
      { "id": 12, "adresse": "test@erasme.org", "principal": true, "academique" : false, "valide": true },
      { "id": 13, "adresse": "test2@erasme.org", "principal": false, "academique" : false, "valide": true }
    ],
    telephones: [
      {id: 1, numero: "0478963214", type_telephone_id: "MAIS"}
      {id: 2, numero: "0678963214", type_telephone_id: "PORT"}
    ],
    "etablissements": [
      { 
        id: "1",
        "nom": "Collège privé St Didier",
        "profils": [ "Enseignant", "Parent" ],
        rights: [
          {"READ" service_id: "USER"}
          {"READ" service_id: "STORAGE", parent_service_id:"ETAB"}
        ],
        relations_eleve: [
          {
            user_id: "vaa60001", eleve_id: "vaa60002", 
            type_relation_eleve_id: "PAR",
            rights: [
              {"READ" service_id: "STORAGE"},
              {"READ" service_id: "NOTE"}
            ]
          }
        ],
        classes: [
          {
            id: 1, 
            nom: "4emeC",
            role: ["PROF", "PROF_PRINCIPAL"]
            "matieres_enseignees": [ { "id": 2, "nom": "Anglais" } ]
            rights: [
              {"READ" service_id: "STORAGE"}
            ]
            blog: {
              id: 2,
              adresse: "classe.blogs.laclasse.com",
              rights: [{"ADMIN", service_id: "BLOG"}]
            }
          }
        ],
        groupes_eleves: [
          {
            id: 1, 
            nom: "4eme ANGLAIS",
            "matieres_enseignees": [ { "id": 2, "nom": "Anglais" } ]
            rights: [
              {code:"READ", service_id: "STORAGE"}
            ]
            blog: {
              id: 2,
              adresse: "groupe.blogs.laclasse.com",
              rights: [{"ADMIN", service_id: "BLOG"}]
            }
          }
        ]
      },
      {
        "id": 2,
        "nom": "Collège Public Maurice",
        "profils": [ "Parent" ],
        rights: [{"READ" service_id: "STORAGE"}]
        classes: [
          {
            id: 3,
            nom: "3emeA",
            role: ["PARENT"],
            rights: [
              {"READ" service_id: "STORAGE"}
              {"READ" service_id: "CAHIER"}
            ]
          }
        ]
      }
    ],
    "groupes_libres": [
      {
        "id": 5,
        "nom": "Super groupe libre",
        "rights": [
          {code:"CREATE", service_id: "STORAGE"}
          {code:"ADD_USER", service_id: "LIBRE"}
        ]
      }  
    ],
    "preferences":[
      {
          "code" : "app_code"
          "valeur": "value"
          "valeur_defaut": "default"

      }
    ]
    "storage": {"id": 123},
    "agenda": {id: 24},
    "cahier_textes": {id:12}
    "email": {id: "toto@laclasse.com"}
  }
  `

## /etablissement

  `
// creer un etablissement
  POST /etablissement
  { "id": 1234, "nom": "Saint Honoré" }
  res 200:
  { "id":  ... }

  //Assigner un role à quelqu'un
  POST /etablissement/:id/user/:user_id/role_user
  {role_id : "ADM_ETB"}
  //Changer le role de quelqu'un
  PUT /etablissement/:id/user/:user_id/role_user/:old_role_id
  {role_id : "PROF"}
  //Supprimer son role sur l'établissement
  DEL /etablissement/:id/user/:user_id/role_user/:role_id

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
  [
  ]

  //Ajout de profils utilisateur
  //Ajoute aussi le role en conséquence
  POST /etablissement/:id/profil_user/:user_id
  {profil_id: "ELV"}

  //Modification d'un profil
  //Modifie le role en conséquence
  PUT /etablissement/:id/profil_user/:user_id/:old_profil_id
  {new_profil_id: "PROF", etablissement_id: 1234}

  //Suppression d'un profil
  //Supprimme le RoleUser associé
  DEL /etablissement/:id/profil_user/:user_id/:profil_id

  //Parametre d'établissement
  //Récupère un parametre précis
  GET /etablissement/:id/parametre/:service_id/:code
  //Modifie un parametre
  PUT /etablissement/:id/parametre/:service_id/:code
  //Remettre la valeure par défaut de la préférence
  DEL /etablissement/:id/parametre/:service_id/:code

  //Récupère tous les paramètres sur un service donné
  GET /etablissement/:id/parametres/:service_id
  //Récupère tous les  paramètres de l'établissement
  GET /etablissement/:id/parametres

  //Gestion de l'activation des services
  GET /etablissement/:id/services_actifs
  {"GED": true, "CAHIER_TXT": false}
  PUT /etablissement/:id/services_actifs/:service_id
  {actif: true|false}

############### 
ressource etablissment 
{
  nom: "", 
  .
  .
  libelle: "", 
  type_etablissement: "college public";
  adresse: "18, ..", 
  longitude: , 
  latitude: , 

  classes
  [{ nom: "", 
     id: "",  
     niveau: "", 

  }, 
  ]

  groupes_eleves
  [{

  }, 
  ]
}

  `

## /matiere
  `
  //Permet de chercher une matière parmis les quelques 2600 fournient par la BCN
  GET /matiere/?query="Fran"&niveau="4EME"
  `

## /libre (groupes libres)
  `
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
  `

## /classe

  `
  //Récupérer tous les niveaux possibles
  GET /classe/niveaux/
  ["CP",... "4EME"... "Terminale"]
  `

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

  //Récupérer la liste des comptes et des mots de passe créer automatiquement
  GET /alimentation/:etablissement_id/:type (eleve, parents ou personnel education nationale)

## Paramètre d'établissement et Préférence utilisateur

  //Récupérer un paramètre
  GET /param/:param_id
  {id: 1, service_id: "GED", type_param_id: "BOOL", code: "affiche_photo", preference: true}
  //Créer un paramètre
  POST /param/
  {service_id: "GED", type_param_id: "BOOL", code: "affiche_photo", preference: true}
  PUT /param/:param_id
  {preference: false}
  DEL /param/:param_id
  //Récupère les paramètres d'un service
  GET /params/:service_id
  [{id: 1, code: ""...}, {id: 2, code: "..."}]
  //Récupère tous les paramètres
  GET /params
  {
    "GED" : [{id: 1, code: ""...}, {id: 2, code: "..."}]
    "CAHIER_TXT" : [{id: 1, code: ""...}, {id: 2, code: "..."}]
  }

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


service-annuaire
================

ATTENTION : CE PROJET COMMENCE A PEINE ET N'EST PAS DU TOUT A UN STADE UTILISABLE. LES SOURCES SONT DISPONIBLES A TITRE INFORMATIF. BEAUCOUP DE CHOSES SONT ENCORE AMENEES A BOUGER DANS LA STRUCTURE DES DONNEES ET L'API UTILISATEUR.


Ensemble de service web pour manipuler les données d'annuaire dans laclasse.com

# Documentation de l'API

ATTENTION, il ne s'agit pas forcément de l'api actuelle mais de ce que l'on aimerait avoir

## /user et /users

Permet de manipuler les utilisateurs ainsi que leur ressources associés (numéro de téléphone, adresse, email, rattachements?)

// open bar, sans cookie
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
}


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

## /regroupement

POST /regroupement
{ "nom": "Test groupe", "droits": [ { "user": "vaa60001", "droit": "admin" } ], "etabs": [ { "id": ... } ] }
res 200:
{ "id" 456, "nom":... }

PUT /regroupement/456/rights
{ user: ,  droit: "membre" }

DELETE /regroupement/456/rights/vaa60001

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
GET /rights/:service/:ressource_id/:user_id
[create_user, add_membre]

//Droits sur un service en général (les services sont aussi des ressources)
GET /rights/service/:service_id



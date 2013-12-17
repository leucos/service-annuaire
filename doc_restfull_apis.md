# Documentation de l'API


## Code d'erreur HTTP utilisés

L'usage de 401 et 403 est inspiré de l'API google drive
1. 400 => La syntaxe de la requète est mauvaise. Soit il manque des paramètres, soit le format des paramètres n'est pas valide (String à la place d'Integer ou Sql Validation failed)
2. 401 => Ce service requiert une authentification et l'utilisateur n'est pas authentifié
3. 403 => L'utilisateur est authentifié mais n'est pas authorizé 
4. 404 => La ressource n'est pas trouvée. La syntaxe de la requète est bonne mais les paramètres ne correspondent pas à une ressource existante (ex : user non existant) ou ne sont pas logique par rapport au path. Ex : l'email n'appartient pas à l'utilisateur dans /user/:user_id/email/:email_id
5. 405 => Si le verbe HTTP utilisé pour un path n'existe pas (exemple appel de DELETE pour un url disponible uniquement en GET) et quand l'url n'existe pas.
6. 200 => success pour les requete (GET, DELETE, PUT)
7. 201 => success pour la requête (POST)

## Documentation swagger
On peux consulter la documentation **swagger** des APIs en accedant au site:
http://petstore.swagger.wordnik.com/ et mettre 
http://localhost:9292/swagger_doc  url de documetation.


##  Les services (APIs) /users

Permet de manipuler les utilisateurs ainsi que leur ressources associés (numéro de téléphone, adresse, email, rattachements?)
Ces APIs Nécessite une **authentification**.

    1. GET /api/users/{user_id} Renvois le profil utilisateur si on donne le bon id.
    2. POST /api/users Service de <!-- création d'un utilisateur -->
    3. PUT /api/users/{user_id} Modification d'un compte utilisateur
    4. DELETE /api/users/{user_id} Supprission d'un compte utilisateur
    5. GET /api/users/{user_id}/relations
    6. POST /api/users/{user_id}/relation Ajout d'une relation entre un adulte et un élève
    7. PUT /api/users/{user_id}/relation/{eleve_id} Modification de la relation
    8. DELETE /api/users/{user_id}/relation/{eleve_id} suppression d'une relation adulte/eleve
    9. GET /api/users/{user_id}/emails recuperer la liste des emails
    10. POST /api/users/{user_id}/email ajouter un email à l'utilisateur
    11. PUT /api/users/{user_id}/email/{email_id} modifier un email existant
    12. DELETE /api/users/{user_id}/email/{email_id} supprimer un email
    13. GET /api/users/{user_id}/email/{email_id}/validate Envois un email de verification à l'utilisateur sur 
          l'email choisit
    14. GET /api/users/{user_id}/email/{email_id}/validate/{validation_key} Envois un email de verification à 
          l'utilisateur sur l'email choisit
    15. GET /api/users/{user_id}/telephones recuperer les telephones
    16. POST /api/users/{user_id}/telephone ajouter un numero de telephone à l'utilisateur
    17. PUT /api/users/{user_id}/telephone/{telephone_id} modifier un telephone
    18. DELETE /api/users/{user_id}/telephone/{telephone_id} suppression d'un telephone
    19. GET /api/users/{user_id}/application/{application_id}/preferences Récupère les préférences d'une 
          application d'un utilisateur
    20. PUT /api/users/{user_id}/application/{application_id}/preferences Modifier une(des) preferecne(s)
    21. DELETE /api/users/{user_id}/application/{application_id}/preferences Remettre la valeure par défaut pour 
          toutes les préférences
    22. GET /api/users/forgot_password Procedure de regénération des mots de passe. Envois un mail à la personne à        qui le login ou l'adresse mail appartient
    23. GET /api/users/login_available  Simple service permettant de savoir si un login est disponible et valide
    24. GET /api/users Service de recherche d'utilisateurs au niveau de LACLASSE
    25. POST /api/users/{user_id}/roles/{role_id}/{etab_id} Assigner un role à un utilisateur
    26. PUT /api/users/{user_id}/roles/{old_role_id}/{etab_id} Modifier le role de quelqu'un
    27. DELETE /api/users/{user_id}/roles/{role_id}/{etab_id} Supprimer le role de l'utilisateu

    //TODO:
    //Activation avec code
    //Gestion des rattachement à un autre fournisseur d'identité ?!

### La ressource (utilisateur) (example):

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

## Les APIs Etablissement:


----------------------    
    1. POST /api/etablissements creer un etablissement
    2. GET  /api/etablissements/{id} return etablissement details
    3. PUT  /api/etablissements/{id} Modifier l'info d'un etablissement
    4. DELETE /api/etablissements/{id} Supprimer un etablissement
--------------------
    5. POST /api/etablissements/{id}/upload/logo Upload an image(logo)  
------------------- 
    6. GET /api/etablissements/{id}/users get the list of users in an etablissement and search users in the etab    lissement
    7. POST /api/etablissements/{id}/users Create user in the etablissement
    8. PUT /api/etablissements/{id}/users/{user_id} Modify user info in the (etablissemnt)
    9. DELETE /api/etablissements/{id}/users/{user_id} Delete a user from the etablissement
---------------------
    10. DELETE /api/etablissements/{id}/users/list/{ids} Delete a list of users from the etablissement
---------------------
    11. GET /api/etablissements/{id}/eleves get the list of (eleves libres) which are not in any class
    12. GET /api/etablissements/{id}/profs get the list of (profs) in (Etablissement)
    13. GET /api/etablissements get la liste des etablissements and search
------------------- 
    14. POST /api/etablissements/{id}/users/{user_id}/role_user Assigner un role à un utilisateur
    15. PUT /api/etablissements/{id}/usesr/{user_id}/role_user/{old_role_id} Changer le role de quelqu'un
    16. DELETE /api/etablissements/{id}/users/{user_id}/role_user/{role_id} Supprimer un role de l'utilisateur dan    s l'etablissement
----------------------
    17. GET /api/etablissements/{id}/classes list all classes in the etablissement
    18. POST /api/etablissements/{id}/classes creer une classe dans l'etablissement
    19. PUT /api/etablissements/{id}/classes/{classe_id} Modifier l'info d'une classe
    20. GET /api/etablissements/{id}/classes/{classe_id} get l'info d'une classe
    21. DELETE /api/etablissements/{id}/classes/{classe_id} Suppression d'une classe
    
----------------------
    22. POST /api/etablissements/{id}/classes/{classe_id}/eleves/{user_id} rattachements d'un eleve à une classe
    23. DELETE /api/etablissements/{id}/classes/{classe_id}/eleves/{user_id} Detachement d'un eleve d'une classe
    
----------------------
    24. GET /api/etablissements/{id}/classes/{classe_id}/profs Lister les enseignants dans une classe
    25. POST /api/etablissements/{id}/classes/{classe_id}/profs/{user_id} Ajouter un enseignant et ajouter des ma   tieres
    26. DELETE /api/etablissements/{id}/classes/{classe_id}/profs/{user_id} supprimer un enseignant 
----------------------
    37. DELETE /api/etablissements/{id}/classe/{classe_id}/profs/{user_id}/matieres/{matiere_id} supprimer une matieres
    
    28. POST /api/etablissements/{id}/classes/{classe_id}/role_user/{user_id} Gestion des rattachements et des ro   les
    29. PUT /api/etablissements/{id}/classe/{classe_id}/role_user/{user_id}/{old_role_id} modifier le role d'un u   tilisateur dans une classe
    30. DELETE /api/etablissements/{id}/classe/{classe_id}/role_user/{user_id}/{role_id} Dettachement
----------------------  
    31. GET /api/etablissements/{id}/matieres lister les matieres enseignees dans letablissement
----------------------
    32. GET /api/etablissements/{id}/groupes lister les groupes d'éléve dans l'etablissement
    33. GET /api/etablissements/{id}/groupes/{groupe_id} Retourner les infos d'un groupe d'eleve
    34. POST /api/etablissements/{id}/groupes creer un groupe d'eleve
    35. PUT /api/etablissements/{id}/groupes/{groupe_id} Modifier l'info d'un groupe d'eleve
    36. DELETE /api/etablissements/{id}/groupes/{groupe_id} Suppression d'un groupe
    37. GET /api/etablissements/{id}/groupes/{groupe_id}/profs Retournez la liste des prof dans un groupe
    38. POST /api/etablissements/{id}/groupes/{groupe_id}/profs/{user_id} Ajouter un enseignant et ajouter des matieres à un groupe
    39. DELETE /api/etablissements/{id}/groupes/{groupe_id}/profs/{user_id} supprimer un enseignant d'un groupe
    
    40. GET /api/etablissements/{id}/groupes/{groupe_id}/eleves retourner la liste des eleves dans un groupe
    41. DELETE /api/etablissements/{id}/groupes/{groupe_id}/profs/{user_id}/matieres/{matiere_id} supprimer une matieres liée à un prof d'un groupe
    42. POST /api/etablissements/{id}/groupes/{groupe_id}/eleves/{user_id} rattachements d'un eleve à un groupe
    43. DELETE /api/etablissements/{id}/groupes/{groupe_id}/eleves/{user_id} Detachement d'un eleve d'une classe
----------------------
    44. POST /api/etablissements/{id}/groupe/{groupe_id}/role_user/{user_id} Rattacher un role a un utilisateur dans un groupe d'eleve
    45. PUT /api/etablissements/{id}/groupe/{groupe_id}/role_user/{user_id}/{old_role_id} modifier le role d'un utilisateur dans un groupe
    46. DELETE /api/etablissements/{id}/groupe/{groupe_id}/role_user/{user_id}/{role_id} supprimer un role dans un groupe d'eleves
-----------------------
    47. GET /api/etablissements/{id}/groupes_libres liste les groupes libres dans un etablissement
    48. GET /api/etablissements/{id}/groupes_libres/{groupe_id} retournez les details d'un groupe libre
    49. POST /api/etablissements/{id}/groupes_libres creation d'un groupe libre
    50. PUT /api/etablissements/{id}/groupes_libres/{groupe_id} modification d'un groupe libre
    51. DELETE /api/etablissements/{id}/groupes_libres/{groupe_id} suppression d'un groupe libre
    52. POST /api/etablissements/{id}/groupes_libres/{groupe_id}/membres Ajouter un membre au regroupement Libre
    53. DELETE /api/etablissements/{id}/groupes_libres/{groupe_id}/membres/{membre_id} supprimer un membre du groupe
-----------------------
    54. POST /api/etablissements/{id}/groupe_eleve/{groupe_id}/role_user/{user_id} gestion des role dans un groupe d'eleves
    55. GET /api/etablissements/{id}/niveaux Recuperer les niveaux des classes
    56. POST /api/etablissements/{id}/profil_user/{user_id} Ajout d'un profils utilisateur
    57. PUT /api/etablissements/{id}/profil_user/{user_id}/{old_profil_id} Modification d'un profil
    58. DELETE /api/etablissements/{id}/profil_user/{user_id}/{profil_id} Suppression d'un profil
    59. GET /api/etablissements/{id}/applications/{app_id}/parametres Recupere tous les parametres sur une application donnee
    60. GET /api/etablissements/{id}/parametres/{app_id}/{code} Recupere la valeur d'un parametre precis
    61. PUT /api/etablissements/{id}/applications/{app_id}/parametres/{param_id} Modifie la valeur d'un parametre
    62. DELETE /api/etablissements/{id}/applications/{app_id}/parametres/{code} Remettre la valeure par defaut du parametre
    63. GET /api/etablissements/{id}/parametres Recupere tous les parametres de l'etablissement pour tous les applications
    64. GET /api/etablissements/{id}/application_actifs Gestion de l'activation des applications
    65. GET /api/etablissements/{id}/applications Return the list of applications in the (etablissement)
    66. PUT /api/etablissements/{id}/applications/{app_id} Activer ou desactiver une application
    67. POST /api/etablissements/{id}/applications/{app_id} Ajouter une application à l'etablissement
    68. DELETE /api/etablissements/{id}/applications/{app_id} supprimer l'application de l'etablissement
    69. GET /api/etablissements/types/types_etablissements Return the list of (etablissements) type


Examples  

      creer un etablissement
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

### La ressource etablissment 
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

## matieres:
    Permet de chercher une matière parmis les quelques 2600 fournient par la BCN
    GET /matieres/?query="Fran"&niveau="4EME"

## groupes libres:
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

## classe:

  //Récupérer tous les niveaux possibles
  GET /classe/niveaux/
  ["CP",... "4EME"... "Terminale"]

## alimentation:

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
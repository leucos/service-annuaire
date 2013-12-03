service-annuaire
================

## Authentification 
L'authentification est un aspect très important dans cet application 
et ça comporte deux types d'authentification:

### Authentifier les utilisateurs directement au sien de serveur des apis
ça se fait par le biais de cookies(sevrer CAS)

### Authentifier une Application(e.g gestion de document)
Une chaîne de caractères  est d'abord créé en utilisant la requête.

Les paramétrés sont triés par ordre alphabétique, et ensuite concaténé.

On ajoute à cet chaîne le timestap ts et la clé privé.

La chaîne de la chaîne est calculé comme suit :

String = 'request uri,(parametres triés et concatenés (e.g p1=v1&p2=v2)),(ts=timestamp),(key=private_key)'

Cette chaîne est ensuite utilisé pour créer la signature qui est un Base64 codé SHA1 HMAC , en utilisant la clé privée secrète de l'application.

Cette signature est ensuite ajouté à la requete avec l'id de l'application: signature="HMAC"&app=app_id 

Signature = Base64(HMAC.digest(Digest.new('sha1'), private_key, String))

Du côté du serveur, le SHA1 HMAC est calculé de la même manière en utilisant les paramétres de demande et la clé secrète du client, qui est connu pour seul le client et le serveur.

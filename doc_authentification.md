service-annuaire
================

## Authentification 
L'authentification est un aspect très important dans cet application 
et ça comporte deux types d'authentification:

### Authentifier les utilisateurs directement au sien de serveur des apis
ça se fait par le biais de cookies(sevrer CAS)

### Authentifier une Application (e.g gestion de document)
Une chaîne de caractères est d'abord créé en utilisant la requête (canonical_string).

Les paramétrés sont triés par ordre alphabétique, et ensuite concaténés.

On ajoute à cet chaîne le timestap(ts) et la clé privé(peut-etre pas necessaire!).

La chaîne(canonical String) est calculé comme suit :
    canonical_string = uri + '/' +  service +'?' 
    parameters = Hash[args.sort]  
    canonical_string += parameters.collect{|key, value| [key.to_s, CGI::escape(value.to_s)].join('=')}.join('&') 
    canonical_string += ';' 
    canonical_string += timestamp	
    canonical_string += ';' 
    canonical_string += app_id 
 
ensuit on signe avec sha1 hmac:
    singature = SHA1.hmac(canonical_string, secret_key) 

Donc, la requete à envoyer: 
    signed request = uri + '/' + service + '?' + query_parameters +";signature=signature;app_id=app_id `

envoyez la requete signée ...


Du côté du serveur, le SHA1 HMAC est calculé de la même manière en utilisant les paramétres de demande et la clé secrète du client, qui est connu seulement par le client et le serveur.

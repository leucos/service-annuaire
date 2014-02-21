## Api's liées aux applications
Dans de fichier on documente les api's ouvertes aux autres applications(Doc, cahier de text, etc ..)

1. get "api/app/etablissements" retourne la liste des etablissements alimentés dans l'annuaire.
2. get "api/app/etablissements/:uai" retourne les infos d'un etablissement( plus de details en ajoutant l'option expand=true)
3. get "api/app/users" retourne la liste de tous les utilisateurs dans l'annuaire.
4. get "api/app/users/:id" retourne les details d'un utilisateur( plus de details avec l'option expand=true)
5. get "api/app/users/liste/:ids" retourner les details d'une liste(ids) d'utilisateurs
6. get "api/app/mateires" retourner la liste de toutes matieres enseignées ..
7. get "api/app/matieres/libelle/:libelle" renvoyer (matiere id) pour  une (libelle)
8. get "api/app/matieres/:matiere_id" renoveyer les details d'une matiere
9. get "api/app/regroupements?etablissement=&nom="  retourne l'id d'un regroupemement dans l'etablissement et le nom dans la requete
10. get "api/app/regroupements/:id" retourne les details d'un regroupement(expand=true => plus de details)
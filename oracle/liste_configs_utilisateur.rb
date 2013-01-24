class ListeConfigsUtilisateur < Sequel::Model(:liste_configs_utilisateur)
  self.db = ORACLE
  many_to_one :utilisateurs, :class=>:Utilisateur, :key => :usr_id
  many_to_one :etablissements, :class=>:Etablissement, :key => :etb_id
  many_to_one :profil, :class=>:Profil, :key => :prof_id

  plugin :typecast_int, :usr_id, :etb_id, :prof_id, :id
end
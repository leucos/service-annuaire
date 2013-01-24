class Utilisateur < Sequel::Model
  self.db = ORACLE
  one_to_one :utilisateurs_info, :key => :id
  one_to_one :roles_user, :key => :usr_id
  one_to_many :liste_configs_utilisateur, :key => :usr_id

  # Ces champs n'ont pas été définis comme integer dans ORACLE
  plugin :typecast_int, :id, :id_user_bdd, :usr_id
end

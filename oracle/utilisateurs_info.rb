class UtilisateursInfo < Sequel::Model(:utilisateurs_info)
  self.db = ORACLE
  one_to_one :utilisateurs, :class=> :Utilisateur, :key => :id
  many_to_one :classes, :class=>:Classe, :key => :cls_id
  many_to_one :etablissement, :class =>:Etablissement, :key => :etb_id
  many_to_one :profil, :class =>:Profil, :key => :prof_id

  plugin :typecast_on_load, :id, :usr_id, :etb_id, :cls_id
  db_schema[:id][:type] = :integer
end
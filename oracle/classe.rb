class Classe < Sequel::Model
  self.db = ORACLE
  one_to_many :utilisateurs_info, :key => :cls_id

  plugin :typecast_int, :niv_id, :nb_docs_elv, :taille_docs_elv
end

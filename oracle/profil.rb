class ProfilOracle < Sequel::Model(:profil)
  self.db = ORACLE
  plugin :typecast_int, :id
end
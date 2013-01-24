class EtablissementOracle < Sequel::Model(:etablissements)
  self.db = ORACLE
  plugin :typecast_int, :marquage_ministere, :zon_id, :mti_id, :monnaie, :_latitude, :_longitude
end

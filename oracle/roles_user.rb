class RolesUser < Sequel::Model
  self.db = ORACLE
  many_to_one :role, :key       => :rol_id
  one_to_one :utilisateur, :key => :usr_id

  plugin :typecast_int, :id, :usr_id, :rol_id
end


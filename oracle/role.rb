class RoleOracle < Sequel::Model(:roles)
  self.db = ORACLE
  one_to_many :roles_user, :key => :rol_id
  many_to_one :environnement, :key => :env_id

  plugin :typecast_int, :id, :tro_id, :env_id
end

class Environnement < Sequel::Model(:environnement)
  self.db = ORACLE
	one_to_many :role, :key => :env_id

  plugin :typecast_int, :id, :look_id, :type_env_id, :usr_id
end

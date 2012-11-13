require 'securerandom'
require 'redis'

class AuthSession
  class UnauthorizedDeletion < StandardError
  end

  @@redis = Redis.new(AuthConfig::REDIS_CONFIG)
   #Ramaze::Cache.options.session = Ramaze::Cache::Redis.using(AuthConfig::REDIS_CONFIG) 
    
  # Créer les clés pour les sessions enregistrées
  def self.init
    AuthConfig::STORED_SESSION.each do |k, v|
      set(k, v)
    end
  end

  def self.get(key)
  	@@redis.get(key)
  end

  def self.time_to_live(key)
    @@redis.ttl(key)
  end

  # deletes the value and the key
  # raise UnauthorizedDeletion si il s'agit d'une session stockée
  def self.delete(key)
    raise UnauthorizedDeletion.new if AuthConfig::STORED_SESSION[key]
    raise UnauthorizedDeletion.new if AuthConfig::STORED_SESSION.rassoc(key)

    value = @@redis.get(key)
    if value
  	  @@redis.del(key)
      @@redis.del(value)
    end 
  end

  def self.exist?(key)
  	@@redis.exists(key)
  end

  # Génère un id de session unique et l'associe à un id d'utlisateur
  # Met un time to live à 1H
  # todo : empêcher la création de session pour des utilisateurs inexistant ?
  def self.create(user_id)
    # Ne change pas la session si elle est statique
    stored_session = AuthConfig::STORED_SESSION[user_id]
    return stored_session if stored_session

  	key = SecureRandom.urlsafe_base64
  	set(key, user_id, 3600)
  	return key
  end

  def self.expire(key,time_in_seconds)
    @@redis.expire(key,time_in_seconds)
    value = @@redis.get(key)
    @@redis.expire(value, time_in_seconds)
  end

  #Créer aussi une entrée avec comme clé la valeur
  def self.set(key, value, ttl= nil)
    @@redis.set(key, value)
    @@redis.set(value, key)
    expire(key, ttl) if ttl
  end
end 
require 'securerandom'
require 'ramaze'
require 'redis'

class AuthSession
  @@redis = Redis.new(AuthConfig::REDIS_CONFIG)
   #Ramaze::Cache.options.session = Ramaze::Cache::Redis.using(AuthConfig::REDIS_CONFIG) 
    

  def self.set(key,value, ttl= nil)
  	@@redis.set(key, value)
    @@redis.expire(key, ttl) if ttl
  end


  def self.get(key)
  	@@redis.get(key)
  end

  # deletes the value and the key
  def self.delete(key)
    value = @@redis.get(key)
    if value
  	  @@redis.del(key)
      @@redis.del(value)
    end 
  end

  def self.exist?(key)
  	@@redis.exists(key)
  end

  def self.new(user_id)
    if self.exist?(user_id) # user has already a session
      self.delete(user_id)
    end  
  	key = SecureRandom.urlsafe_base64 
  	@@redis.set(key, user_id)
  	@@redis.set(user_id, key)
  	return key
  end

  def self.expire(key,time_in_seconds)
    @@redis.expire(key,time_in_seconds)
    value = @@redis.get(key)
    @@redis.expire(value, time_in_seconds)
  end

  def self.time_to_live(key)
    @@redis.ttl(key)
  end

  def self.incr_time_to_live(key, ttl)
    if @@redis.exists(key) and @@redis.ttl(key) != -1
      value = @@redis.get(key)
      # add one hour 
      @@redis.expire(value, @@redis.ttl(value)+ttl)
      @@redis.expire(key, @@redis.ttl(key)+ttl)
    else 
      false 
    end  
  end  
end 
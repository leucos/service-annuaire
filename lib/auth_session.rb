# todo  modify to use Search in CAS server Redis
# note: tickets in the CAS server is related to login => search user by login and not id
class AuthSession
  class UnauthorizedDeletion < StandardError
  end
  class UserNotFound < StandardError
  end
  
  # Ajoute simplement le path REDIS à la clé
  def self.key(key)
    "#{REDIS_PATH}.#{AuthConfig::SESSION_PATH}-#{key}"
  end

  # Créer les clés pour les sessions enregistrées
  def self.init
    AuthConfig::STORED_SESSION.each do |user_id, session_id|
      if User[user_id].nil?
        Laclasse::Log.error("Attention utilisateur #{user_id} inexistant pour la session #{session_id}")
      end
      # La clé d'une session stockée est l'utilisateur car on ne peut
      # pas avoir plusieurs session pour un même utilisateur stocké
      # Note : pas d'expiration pour les session stockées
      REDIS.set(key(session_id), user_id)
    end
  end

  # Met à jour le ttl de la clé si ce n'est pas une clé stockée (ttl == -1)
  def self.get(key)
  	value = REDIS.get(key(key))
    if value and REDIS.ttl(key(key)) != -1
      REDIS.expire(key(key), AuthConfig::SESSION_DURATION)
    end

    return value
  end

  # deletes the value and the key
  # raise UnauthorizedDeletion si il s'agit d'une session stockée
  def self.delete(key)
    if !AuthConfig::STORED_SESSION.rassoc(key)
 	    REDIS.del(key(key))
    end  
  end

  # Génère un id de session unique et l'associe à un id d'utlisateur
  # Met un time to live à 1H
  # todo : empêcher la création de session pour des utilisateurs inexistant ?
  def self.create(user_id, ttl = AuthConfig::SESSION_DURATION)
    raise UserNotFound.new if User[user_id].nil?

    # Ne change pas la session si elle est statique
    stored_session = AuthConfig::STORED_SESSION[user_id]
    return stored_session if stored_session

  	key = SecureRandom.urlsafe_base64
  	REDIS.setex(key(key), ttl, user_id)
  	return key
  end
end 
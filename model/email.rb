#coding: utf-8
#
# model for 'email' table
# generated 2012-04-25 15:54:20 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# adresse                       | varchar(255)        | false    |          |            | 
# principal                     | tinyint(1)          | false    |          | 1          | 
# valide                        | tinyint(1)          | false    |          | 0          | 
# academique                    | tinyint(1)          | false    |          | 0          | 
# user_id                       | char(8)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Email < Sequel::Model(:email)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :user

  # Not nullable cols
  def validate
    super
    validates_presence [:adresse, :user_id]
    # On ne peut avoir qu'un seul email principal
    email_principal = Email.filter(:user_id => user_id, :principal => true).first
    if email_principal and email_principal.id != id and (principal.nil? or principal)
      errors.add(:principal, "On ne peut pas avoir 2 mails principaux")
    end
  end

  # Envois par mail une clé de validation de l'email
  # Qui aura une durée de vie de quelques heures
  def generate_validation_key
    key = SecureRandom.urlsafe_base64
    REDIS.setex("#{REDIS_PATH}.#{EMAIL_PATH}.#{key}", EMAIL_DURATION, self.id)
    return key
  end

  # Vérifie si la clé de validation passée en paramètre est bien lié à cet email
  # Si c'est le cas, alors l'email est valide
  # return false si la clé est expirée ou ne correspond pas à cet email
  def check_validation_key(key)
    key = "#{REDIS_PATH}.#{EMAIL_PATH}.#{key}"
    if REDIS.get(key).to_i == self.id
      self.update(:valide => true)
      # La clé ne sert qu'une fois
      REDIS.del(key)
      return true
    else
      return false
    end
  end

  # Envois un email de validation à l'adresse définie dans l'email
  def send_validation_mail
    validation_key = generate_validation_key
    adresse = self.adresse
    user = self.user
    mail_id = self.id

    #TEMP : pour éviter d'avoir des erreurs avec gmail notamment mais peut-être mettre ailleurs
    
    # J'ai honteusement pompé sur le message de vérification de mail de GitHub
    mail = Mail.new do
      to adresse
      from "noreply@laclasse.com"
      subject "[laclasse.com] Merci de vérfier votre adresse email '#{adresse}'"
      # todo : ne pas mettre l'adresse laclasse.com en dur
      body(
"Bonjour,

Ceci est un message pour vérfier que vous êtes bien #{user.full_name}. 
Si c'est le cas, merci de suivre le lien ci-dessous :
https://www.laclasse.com/annuaire/user/#{user.id}/email/#{mail_id}/validate/#{validation_key}

Si vous n'êtes pas #{user.full_name} ou que vous n'avez pas demandé d'email de vérification, merci d'ignorer ce message.

Cordialement,

L'équipe laclasse.com")
    end
    # Dommage que l'on ne peut pas préciser ça dans le deliver...
    mail.charset = 'utf-8'
    mail.deliver
  end
end

#coding: utf-8
#
# model for 'profil_user' table
# generated 2012-05-30 17:44:02 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# user_id                       | char(8)             | false    | PRI      |            | 
# etablissement_id              | char(8)             | false    | PRI      |            | 
# profil_id                     | char(4)             | false    | PRI      |            | 
# bloque                        | tinyint(1)          | true     |          |            | 
# actif                         | tinyint(1)          | false    |          | 0          | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ProfilUser < Sequel::Model(:profil_user)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :etablissement
  many_to_one :profil
  many_to_one :user
  one_to_many :role_user, :key=>[:profil_user_user_id, :profil_user_etablissement_id, :profil_user_profil_id]

  # Not nullable cols
  def validate
    super
    #todo : Vérifier qu'on ne rajoute pas un compte actif alors qu'il y en a déjà un
  end
end

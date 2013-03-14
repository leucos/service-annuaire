#coding: utf-8
#
# model for 'profil_user_has_fonction' table
# generated 2012-10-26 17:22:55 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# profil_user_profil_id         | char(8)             | false    | PRI      |            | 
# profil_user_user_id           | char(16)            | false    | PRI      |            | 
# profil_user_etablissement_id  | int(11)             | false    | PRI      |            | 
# fonction_id                   | int                 | false    | FOR      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ProfilUserFonction < Sequel::Model(:profil_user_has_fonction)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  unrestrict_primary_key()

  # Referential integrity
  many_to_one :profil_user
  many_to_one :fonction
  #one_to_many :profil_user_has_fonction

  # Not nullable cols and unicity validation
  def validate
    super
  end
end

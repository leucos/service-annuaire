#coding: utf-8
#
# model for 'role_user' table
# generated 2012-06-05 10:19:46 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# role_id                       | int(11)             | false    | PRI      |            | 
# profil_user_user_id           | char(8)             | false    | PRI      |            | 
# profil_user_etablissement_id  | char(8)             | false    | PRI      |            | 
# profil_user_profil_id         | char(4)             | false    | PRI      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class RoleUser < Sequel::Model(:role_user)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :role
  many_to_one :profil_user, :key=>[:profil_user_user_id, :profil_user_etablissement_id, :profil_user_profil_id]

  # Not nullable cols
  def validate
    super
  end
end

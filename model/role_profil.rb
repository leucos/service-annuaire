#coding: utf-8
#
# model for 'role_profil' table
# generated 2012-10-19 17:11:43 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# role_id                       | int(11)             | false    | PRI      |            | 
# profil_id                     | char(4)             | false    | PRI      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class RoleProfil < Sequel::Model(:role_profil)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :role
  many_to_one :profil

  # Not nullable cols and unicity validation
  def validate
    super
  end
end

#coding: utf-8
#
# model for 'role_profil' table
# generated 2012-04-19 17:45:32 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# role_id                       | int(11)             | false    | PRI      |            | 
# profil_id                     | int(11)             | false    | PRI      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class RoleProfil < Sequel::Model(:role_profil)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :profil
  many_to_one :role

  # Not nullable cols
  def validate
  end
end

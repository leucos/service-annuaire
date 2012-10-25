#coding: utf-8
#
# model for 'role_user' table
# generated 2012-10-23 17:28:07 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# role_id                       | char(8)             | false    | PRI      |            | 
# user_id                       | char(16)            | false    | PRI      |            | 
# ressource_service_id          | char(8)             | false    | PRI      |            | 
# ressource_id                  | varchar(255)        | false    | PRI      |            | 
# bloque                        | tinyint(1)          | false    |          | 0          | 
# actif                         | tinyint(1)          | true     |          | 1          | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class RoleUser < Sequel::Model(:role_user)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :role
  many_to_one :user
  many_to_one :ressource, :key=>[:ressource_service_id, :ressource_id]

  # Not nullable cols and unicity validation
  def validate
    super
  end
end

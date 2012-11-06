#coding: utf-8
#
# model for 'role_user' table
# generated 2012-10-29 10:38:47 +0100 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# user_id                       | char(16)            | false    | PRI      |            | 
# ressource_service_id          | char(8)             | false    | PRI      |            | 
# ressource_id                  | varchar(255)        | false    | PRI      |            | 
# bloque                        | tinyint(1)          | false    |          | 0          | 
# actif                         | tinyint(1)          | true     |          | 1          | 
# role_id                       | char(8)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class RoleUser < Sequel::Model(:role_user)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  unrestrict_primary_key()

  # Referential integrity
  many_to_one :user
  many_to_one :ressource, :key=>[:ressource_service_id, :ressource_id]
  many_to_one :role

  # Not nullable cols and unicity validation
  def validate
    super
    validates_presence [:role_id]
  end
end

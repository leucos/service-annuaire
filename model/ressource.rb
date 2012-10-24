#coding: utf-8
#
# model for 'ressource' table
# generated 2012-10-23 17:29:17 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | varchar(255)        | false    | PRI      |            | 
# service_id                    | char(8)             | false    | PRI      |            | 
# parent_service_id             | char(8)             | false    | MUL      |            | 
# parent_id                     | varchar(255)        | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Ressource < Sequel::Model(:ressource)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :service
  many_to_one :parent, :key=>[:parent_service_id, :parent_id]
  one_to_many :role_user, :key=>[:ressource_service_id, :ressource_id]

  # Not nullable cols and unicity validation
  def validate
    super
  end
end

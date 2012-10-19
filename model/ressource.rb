#coding: utf-8
#
# model for 'ressource' table
# generated 2012-10-19 17:11:43 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# parent_id                     | int(11)             | true     | MUL      |            | 
# id_externe                    | varchar(255)        | false    |          |            | 
# service_id                    | char(8)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Ressource < Sequel::Model(:ressource)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :ressource, :key=>:parent_id
  many_to_one :service
  one_to_many :role_user

  # Not nullable cols and unicity validation
  def validate
    super
    validates_presence [:id_externe, :service_id]
  end
end

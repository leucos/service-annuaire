#coding: utf-8
#
# model for 'param_service' table
# generated 2012-10-19 17:11:43 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# code                          | varchar(45)         | false    |          |            | 
# preference                    | tinyint(1)          | false    |          |            | 
# libelle                       | varchar(45)         | true     |          |            | 
# description                   | varchar(255)        | true     |          |            | 
# valeur_defaut                 | varchar(2000)       | true     |          |            | 
# autres_valeurs                | varchar(2000)       | true     |          |            | 
# service_id                    | char(8)             | false    | MUL      |            | 
# type_param_id                 | char(4)             | false    | MUL      |            | 
# role_id                       | int(11)             | true     | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ParamService < Sequel::Model(:param_service)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :type_param
  many_to_one :service
  many_to_one :role
  one_to_many :param_etablissement
  one_to_many :param_user

  # Not nullable cols and unicity validation
  def validate
    super
    validates_presence [:code, :preference, :service_id, :type_param_id]
  end
end

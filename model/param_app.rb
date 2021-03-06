#coding: utf-8
#
# model for 'param_app' table
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
# app_id                        | int(11)             | false    | MUL      |            | 
# type_param_id                 | char(4)             | false    | MUL      |            | 
# role_id                       | int(11)             | true     | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ParamApp < Sequel::Model(:param_app)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :app
  many_to_one :role
  many_to_one :type_param

  # Not nullable cols and unicity validation
  def validate
    super
    validates_presence [:code, :preference, :app_id, :type_param_id]
  end
end

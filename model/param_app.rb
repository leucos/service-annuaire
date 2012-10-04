#coding: utf-8
#
# model for 'param_app' table
# generated 2012-07-25 12:55:37 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# code                          | varchar(45)         | true     |          |            | 
# preference                    | tinyint(1)          | false    |          |            | 
# libelle                       | varchar(45)         | true     |          |            | 
# description                   | varchar(255)        | true     |          |            | 
# valeur_defaut                 | varchar(2000)       | true     |          |            | 
# autres_valeurs                | varchar(2000)       | true     |          |            | 
# app_id                        | int(11)             | false    | MUL      |            | 
# type_param_id                 | char(4)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ParamApp < Sequel::Model(:param_app)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :app
  many_to_one :type_param
  one_to_many :param_etablissement
  one_to_many :param_user

  # Not nullable cols
  def validate
    super
    validates_presence [:preference, :app_id, :type_param_id]
  end
end

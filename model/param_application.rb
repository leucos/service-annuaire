#coding: utf-8
#
# model for 'param_application' table
# generated 2012-10-31 10:03:57 +0100 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# code                          | varchar(45)         | false    |          |            | 
# preference                    | tinyint(1)          | false    |          |            | 
# libelle                       | varchar(255)        | true     |          |            | 
# description                   | varchar(1024)       | true     |          |            | 
# valeur_defaut                 | varchar(2000)       | true     |          |            | 
# autres_valeurs                | varchar(2000)       | true     |          |            | 
# type_param_id                 | char(8)             | false    | MUL      |            | 
# application_id                | char(8)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ParamApplication < Sequel::Model(:param_application)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :type_param
  many_to_one :application
  one_to_many :param_etablissement
  one_to_many :param_user

  # Not nullable cols and unicity validation
  def validate
    super
    validates_presence [:code, :preference, :type_param_id, :application_id]
  end

  def before_destroy
    param_user_dataset.destroy()
    param_etablissement_dataset.destroy()
    super
  end
end

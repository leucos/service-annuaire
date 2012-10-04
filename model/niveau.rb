#coding: utf-8
#
# model for 'niveau' table
# generated 2012-04-19 17:45:31 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# libelle                       | varchar(45)         | true     |          |            | 
# description                   | varchar(255)        | true     |          |            | 
# annee                         | int(11)             | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Niveau < Sequel::Model(:niveau)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity

  # Not nullable cols
  def validate
    super
  end
end

#coding: utf-8
#
# model for 'profil' table
# generated 2012-04-19 17:45:32 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | char(4)             | false    | PRI      |            | 
# libelle                       | varchar(45)         | true     |          |            | 
# description                   | varchar(1024)       | true     |          |            | 
# code_men                      | varchar(45)         | true     |          |            | 
# code_national                 | varchar(45)         | true     |          |            | 
# role_id                       | int(11)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Profil < Sequel::Model(:profil)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :role

  # Not nullable cols
  def validate
    super
  end
end

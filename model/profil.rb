#coding: utf-8
#
# model for 'profil' table
# generated 2012-04-19 17:45:32 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# libelle                       | varchar(45)         | true     |          |            | 
# description                   | varchar(1024)       | true     |          |            | 
# code_men                      | varchar(45)         | true     |          |            | 
# code_national                 | varchar(45)         | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Profil < Sequel::Model(:profil)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  one_to_many :profil_user
  one_to_many :role_profil

  # Not nullable cols
  def validate
    super
  end
end

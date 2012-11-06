#coding: utf-8
#
# model for 'fonction' table
# generated 2012-04-25 15:50:19 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | 
# libelle                       | varchar(45)         | true     |          |            | 
# description                   | varchar(1024)       | true     |          |            | 
# code_men                      | varchar(45)         | true     |          |            | 
# profil_id                     | char(8)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Fonction < Sequel::Model(:fonction)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :profil

  # Not nullable cols
  def validate
    super
    validates_presence [:profil_id]
  end
end

#coding: utf-8
#
# model for 'fonction' table
# generated 2012-04-25 15:50:19 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int                 | false    | PRI      |            | 
# libelle                       | varchar(45)         | true     |          |            | 
# description                   | varchar(100)        | true     |          |            | 
# code_men                      | varchar(45)         | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------

# profil_id deleted in the new version
# profil_id                     | char(8)             | false    | MUL      |            | 

#
class Fonction < Sequel::Model(:fonction)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  one_to_many :profil_user_has_fonction

  # Not nullable cols
  def validate
    super
  end
end

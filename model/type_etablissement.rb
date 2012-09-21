#coding: utf-8
#
# model for 'type_etablissement' table
# generated 2012-04-19 17:45:32 +0200 by model_generator.rb
#ram
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# type_etab                     | varchar(80)         | true     |          |            | 
# type_contrat                  | varchar(80)         | true     |          |            | 
# lib_affichage                 | varchar(255)        | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class TypeEtablissement < Sequel::Model(:type_etablissement)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  one_to_many :etablissement

  # Not nullable cols
  def validate
  end

end

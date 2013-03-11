#coding: utf-8
#
# model for 'matiere_enseignee' table
# generated 2012-04-25 12:25:04 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | varchar(10)         | false    | PRI      |            | 
# libelle_court                 | varchar(45)         | true     |          |            | 
# libelle_long                  | varchar(255)        | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class MatiereEnseignee < Sequel::Model(:matiere_enseignee)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  unrestrict_primary_key()

  # Referential integrity
  one_to_many :enseigne_dans_regroupement

  # Not nullable cols
  def validate
    super
  end
end

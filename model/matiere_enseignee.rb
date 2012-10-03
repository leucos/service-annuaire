#coding: utf-8
#
# model for 'matiere_enseignee' table
# generated 2012-04-25 12:25:04 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | 
# libelle_court                 | varchar(45)         | true     |          |            | 
# libelle_long                  | varchar(255)        | true     |          |            | 
# libelle_edition               | varchar(255)        | true     |          |            | 
# famille_matiere_id            | int(11)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class MatiereEnseignee < Sequel::Model(:matiere_enseignee)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :famille_matiere
  one_to_many :enseigne_regroupement

  # Not nullable cols
  def validate
    super
    validates_presence [:famille_matiere_id]
  end
end

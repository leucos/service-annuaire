#coding: utf-8
#
# model for 'eleve_dans_regroupement' table
# generated 2012-04-19 17:45:31 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# user_id                       | char(8)             | false    | PRI      |            | 
# regroupement_id               | int(11)             | false    | PRI      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class EleveDansRegroupement < Sequel::Model(:eleve_dans_regroupement)


  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  unrestrict_primary_key
  # Referential integrity
  many_to_one :regroupement
  many_to_one :user

  # Not nullable cols
  def validate
  end
end
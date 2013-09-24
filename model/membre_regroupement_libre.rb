#coding: utf-8
#
# model for 'membre_regroupement_libre' table
# generated 2012-04-19 17:45:31 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# user_id                       | INT                 | false    | PRI      |            | 
# regroupement_Libre_id         | INT                 | false    | PRI      |            | 
# joind_at                      | DATE                |	true   	 |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class MembreRegroupementLibre < Sequel::Model(:membre_regroupement_libre)


  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  unrestrict_primary_key
  # Referential integrity
  many_to_one :regroupement_libre
  many_to_one :user

  # Not nullable cols
  def validate
  end
end
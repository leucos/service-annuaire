#coding: utf-8
#
# model for 'param_etablissement' table
# generated 2012-07-25 12:54:03 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# param_app_id                  | int(11)             | false    | PRI      |            | 
# etablissement_id              | char(8)             | false    | PRI      |            | 
# valeur                        | varchar(2000)       | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ParamEtablissement < Sequel::Model(:param_etablissement)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :param_app
  many_to_one :etablissement

  # Not nullable cols
  def validate
    super
  end
end

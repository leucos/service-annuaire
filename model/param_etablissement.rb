#coding: utf-8
#
# model for 'param_etablissement' table
# generated 2012-10-19 17:11:43 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# param_application_id              | int(11)             | false    | PRI      |            | 
# etablissement_id              | int(11)             | false    | PRI      |            | 
# valeur                        | varchar(2000)       | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ParamEtablissement < Sequel::Model(:param_etablissement)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  unrestrict_primary_key()

  # Referential integrity
  many_to_one :param_application
  many_to_one :etablissement

  # Not nullable cols and unicity validation
  def validate
    super
  end
end

#coding: utf-8
#
# model for 'application_etablissement' table
# generated 2012-10-31 10:03:57 +0100 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# application_id                | char(8)             | false    | PRI      |            | 
# etablissement_id              | int(11)             | false    | PRI      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ApplicationEtablissement < Sequel::Model(:application_etablissement)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  unrestrict_primary_key()

  # Referential integrity
  many_to_one :application
  many_to_one :etablissement

  # Not nullable cols and unicity validation
  def validate
    super
  end
end

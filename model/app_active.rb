#coding: utf-8
#
# model for 'app_active' table
# generated 2012-04-19 17:45:31 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# application_id                | int(11)             | false    | PRI      |            | 
# etablissement_id              | char(8)             | false    | PRI      |            | 
# active                        | tinyint(1)          | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class AppActive < Sequel::Model(:app_active)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :app, :key=>:application_id
  many_to_one :etablissement
  one_to_many :param_app_active, :key=>[:app_active_application_id, :app_active_etablissement_id]

  # Not nullable cols
  def validate
    super
  end
end

#coding: utf-8
#
# model for 'application' table
# generated 2012-10-31 10:03:57 +0100 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | char(8)             | false    | PRI      |            | 
# libelle                       | varchar(255)        | true     |          |            | 
# description                   | varchar(1024)       | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Application < Sequel::Model(:application)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  one_to_many :application_etablissement
  one_to_many :param_application

  # Not nullable cols and unicity validation
  def validate
    super
  end
end

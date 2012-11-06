#coding: utf-8
#
# model for 'type_telephone' table
# generated 2012-04-19 17:45:32 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | char(8)             | false    | PRI      |            | 
# libelle                       | varchar(45)         | true     |          |            | 
# description                   | varchar(255)        | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class TypeTelephone < Sequel::Model(:type_telephone)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  unrestrict_primary_key()
  
  # Referential integrity
  one_to_many :telephone

  # Not nullable cols
  def validate
    super
  end
end

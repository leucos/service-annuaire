#coding: utf-8
#
# model for 'application_key' table
# generated 2012-10-29 11:19:28 +0100 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# application_id                | char(8)             | false    | PRI      |            | 
# application_key               | varchar(45)         | false    |          |            | 
# application_secret            | varchar(45)         | false    |          |            |
# created_at                    | DATETIME            | false    |          |            |
# validity_duration             | INT                 | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#

class ApplicationKey < Sequel::Model(:application_key)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  unrestrict_primary_key()

  # Referential integrity
  one_to_one:application 

  # Not nullable cols and unicity validation
  def validate
    super
  end
end

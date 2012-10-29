#coding: utf-8
#
# model for 'activite_role' table
# generated 2012-10-29 11:25:29 +0100 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# role_id                       | char(8)             | false    | PRI      |            | 
# service_id                    | char(8)             | false    | PRI      |            | 
# activite_id                   | varchar(45)         | false    | PRI      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ActiviteRole < Sequel::Model(:activite_role)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :role
  many_to_one :service
  many_to_one :activite

  # Not nullable cols and unicity validation
  def validate
    super
  end
end

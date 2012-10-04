#coding: utf-8
#
# model for 'activite_role' table
# generated 2012-04-19 17:45:31 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# activite_id                   | int(11)             | false    | MUL      |            | 
# role_id                       | int(11)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ActiviteRole < Sequel::Model(:activite_role)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :activite
  many_to_one :role

  # Not nullable cols
  def validate
    super
    validates_presence [:activite_id, :role_id]
  end
end

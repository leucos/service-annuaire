#coding: utf-8
#
# model for 'membre_regroupement' table
# generated 2012-10-19 17:11:43 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# user_id                       | char(8)             | false    | PRI      |            | 
# regroupement_id               | int(11)             | false    | PRI      |            | 
# admin                         | tinyint(1)          | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class MembreRegroupement < Sequel::Model(:membre_regroupement)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :regroupement
  many_to_one :user

  # Not nullable cols and unicity validation
  def validate
    super
  end
end

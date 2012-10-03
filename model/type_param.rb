#coding: utf-8
#
# model for 'type_param' table
# generated 2012-07-25 12:54:03 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | char(4)             | false    | PRI      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class TypeParam < Sequel::Model(:type_param)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  one_to_many :param_app

  # Not nullable cols
  def validate
    super
  end
end

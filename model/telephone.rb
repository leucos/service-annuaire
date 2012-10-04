#coding: utf-8
#
# model for 'telephone' table
# generated 2012-04-25 15:54:20 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# numero                        | char(32)            | false    | PRI      |            | 
# user_id                       | char(8)             | false    | PRI      |            | 
# type_telephone_id             | char(4)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Telephone < Sequel::Model(:telephone)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :user
  many_to_one :type_telephone

  # Not nullable cols
  def validate
    super
    validates_presence [:type_telephone_id]
  end
end

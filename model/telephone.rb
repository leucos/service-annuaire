#coding: utf-8
#
# model for 'telephone' table
# generated 2012-04-25 15:54:20 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# numero                        | char(32)            | false    |          |            | 
# user_id                       | char(8)             | false    | MUL      |            | 
# type_telephone_id             | char(8)             | false    | MUL      |            | 
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
    validates_presence [:type_telephone_id, :user_id]
  end
end

#coding: utf-8
#
# model for 'activite' table
# generated 2012-10-19 17:11:42 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# code                          | varchar(45)         | false    |          |            | 
# libelle                       | varchar(45)         | true     |          |            | 
# description                   | varchar(1024)       | true     |          |            | 
# service_id                    | char(8)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Activite < Sequel::Model(:activite)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  one_to_many :activite_role

  # Not nullable cols and unicity validation
  def validate
    super
    validates_presence [:code, :service_id]
  end
end

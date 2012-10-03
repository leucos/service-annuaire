#coding: utf-8
#
# model for 'role' table
# generated 2012-04-19 17:45:32 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# libelle                       | varchar(45)         | true     |          |            | 
# description                   | varchar(255)        | true     |          |            | 
# app_id                        | int(11)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Role < Sequel::Model(:role)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :app
  one_to_many :activite_role
  one_to_many :role_profil
  one_to_many :role_user

  # Not nullable cols
  def validate
    super
    validates_presence [:app_id]
  end
end

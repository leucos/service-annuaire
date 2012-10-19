#coding: utf-8
#
# model for 'param_user' table
# generated 2012-10-19 17:11:43 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# param_service_id              | int(11)             | false    | PRI      |            | 
# user_id                       | char(16)            | false    | PRI      |            | 
# valeur                        | varchar(2000)       | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ParamUser < Sequel::Model(:param_user)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :param_service
  many_to_one :user

  # Not nullable cols and unicity validation
  def validate
    super
  end
end

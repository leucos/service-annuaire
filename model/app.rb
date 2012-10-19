#coding: utf-8
#
# model for 'app' table
# generated 2012-10-19 17:11:42 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# code                          | varchar(45)         | false    | UNI      |            | 
# libelle                       | varchar(255)        | true     |          |            | 
# description                   | varchar(1024)       | true     |          |            | 
# url                           | varchar(1024)       | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class App < Sequel::Model(:app)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  one_to_many :app_active, :key=>:application_id
  one_to_many :param_app

  # Not nullable cols and unicity validation
  def validate
    super
    validates_presence [:code]
    validates_unique :code
  end
end

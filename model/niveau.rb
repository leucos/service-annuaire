#coding: utf-8
#
# model for 'niveau' table
# generated 2012-04-19 17:45:31 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# ent_mef_jointure              | varchar(20)         | false    | PRI      |            | 
# mef_libelle                   | varchar(256)        | true     |          |            | 
# ent_mef_rattach               | varchar(20)         | true     |          |            | 
# ent_mef_stat                  | varchar(20)         | true     |          |            |  

# this table  is feeded by  mef_educ national
class Niveau < Sequel::Model(:niveau)

  unrestrict_primary_key	
  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  # relation with mef_educ_nat table 

  one_to_many :regroupement

  # Not nullable cols
  def validate
    super
  end
end

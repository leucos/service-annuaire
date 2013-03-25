#coding: utf-8
#
# model for 'enseigne_dans_regroupement' table
# generated 2012-05-10 11:52:35 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+--------------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY          | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+--------------+------------+--------------------
# user_id                       | char(8)             | false    | Foreign      |            | 
# regroupement_id               | int(11)             | false    | PRI          |            | 
# matiere_enseignee_id          | varchar(11)         | false    | PRI          |            | 
# prof_principal                | tinyint(1)          | true     |              | 0          | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class EnseigneDansRegroupement < Sequel::Model(:enseigne_dans_regroupement)

 # Plugins
 plugin :validation_helpers
 plugin :json_serializer

 unrestrict_primary_key
 # Referential integrity
 many_to_one :user
 many_to_one :regroupement
 many_to_one :matiere_enseignee

 # Not nullable cols
 def validate
  super
 end
end

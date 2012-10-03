#coding: utf-8
#
# model for 'enseigne_regroupement' table
# generated 2012-05-10 11:52:35 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# user_id                       | char(8)             | false    | PRI      |            | 
# regroupement_id               | int(11)             | false    | PRI      |            | 
# matiere_enseignee_id          | int(11)             | false    | PRI      |            | 
# prof_principal                | tinyint(1)          | true     |          | 0          | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class EnseigneRegroupement < Sequel::Model(:enseigne_regroupement)

 # Plugins
 plugin :validation_helpers
 plugin :json_serializer

 # Referential integrity
 many_to_one :user
 many_to_one :regroupement
 many_to_one :matiere_enseignee

 # Not nullable cols
 def validate
  super
 end
end

#coding: utf-8
#
# model for 'reserved_uid' table
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# reserved_uid                  | char(8)             | false | true        |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
# 
# Génération des UID de la forme Vxx6iiii
# 
#  Cette génération fonctionne comme les immatriculations. Les lettres V et 6 nous sont imposées
#  On commence par VAA60000 et on incrémente le nombre. Une fois à VAA69999, on passe à VAB60000
#  et ainsi de suite.
#
class ReservedUid < Sequel::Model(:reserved_uid)
	
end
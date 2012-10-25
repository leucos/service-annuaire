#coding: utf-8
#
# model for 'service_actif' table
# generated 2012-10-19 17:11:43 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# service_id                    | char(8)             | false    | PRI      |            | 
# etablissement_id              | int(11)             | false    | PRI      |            | 
# actif                         | tinyint(1)          | false    |          | 0          | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ServiceActif < Sequel::Model(:service_actif)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :service
  many_to_one :etablissement

  # Not nullable cols and unicity validation
  def validate
    super
    #todo : Vérifier qu'on ne rajoute pas un compte actif alors qu'il y en a déjà un
  end
end

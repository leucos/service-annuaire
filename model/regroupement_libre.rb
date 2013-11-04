#coding: utf-8
#
# model for 'regroupement_regroupement' table
# generated 2012-04-19 17:45:31 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int                 | false    | PRI      |            | 
# created_at                    | DATE                | true     |          |            | 
# created_by                    | int                 | false    | FKI      |            |
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class RegroupementLibre < Sequel::Model(:regroupement_libre)


  # Plugins
  plugin :validation_helpers
  plugin :json_serializer
  # add/delete resource in the resource table when create/delete
  plugin :ressource_link, :service_id => SRV_LIBRE

  unrestrict_primary_key
  # Referential integrity
  one_to_many :membre_regroupement_libre
  one_to_one :user

  # Not nullable cols
  def validate
  end

  def membres 
    self.membre_regroupement_libre_dataset.join(:user , :user__id => :user_id)
    .select(:id_ent, :nom, :prenom, :joined_at, :user_id)
    .naked.all
  end 
end
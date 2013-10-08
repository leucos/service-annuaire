#coding: utf-8
#
# model for 'role' table
# generated 2012-10-29 11:57:18 +0100 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | char(8)             | false    | PRI      |            | 
# libelle                       | varchar(45)         | true     |          |            | 
# description                   | varchar(255)        | true     |          |            | 
# service_id                    | char(8)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Role < Sequel::Model(:role)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer
  # plugin to create corresponding resource
  plugin :ressource_link, :service_id => SRV_ROLE

  unrestrict_primary_key()

  # Referential integrity
  #many_to_many :service
  one_to_many :activite_role
  #many_to_one :application
  one_to_many :role_user

  # Not nullable cols and unicity validation
  def validate
    super
    #validates_presence [:service_id]
  end

  def before_destroy
    #activite_role_dataset.destroy()
    Ressource[:id => self.id.to_s].destroy if Ressource[:id => self.id.to_s]
    role_user_dataset.destroy()

    super
  end

  def add_activite(service_id, activite_id, condition = "self", type_ressource)
    ActiviteRole.create(:service_id => service_id, :role_id => self.id, 
      :activite_id => activite_id, :condition => condition, :parent_service_id => type_ressource)
  end

  def remove_activite(service_id, activite_id, condition, type_resource)
    activite = ActiviteRole[:service_id => service_id, :role_id => self.id, :activite_id => activite_id, :condition => condition, :parent_service_id => type_resource]
    activite.destroy
  end
end

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

  unrestrict_primary_key()

  # Referential integrity
  many_to_many :service
  #one_to_many :activite_role
  many_to_one :application
  one_to_many :role_user

  # Not nullable cols and unicity validation
  def validate
    super
    validates_presence [:service_id]
  end

  def before_destroy
    #activite_role_dataset.destroy()
    role_user_dataset.destroy()
    super
  end

  def add_activite(service_id, activite_id)
    ActiviteRole.create(:service_id => service_id, :role_id => self.id, :activite_id => activite_id)
  end
end

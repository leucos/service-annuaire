#coding: utf-8
#
# model for 'application' table
# generated 2012-10-31 10:03:57 +0100 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | char(8)             | false    | PRI      |            | 
# libelle                       | varchar(255)        | true     |          |            | 
# description                   | varchar(1024)       | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Application < Sequel::Model(:application)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # link to resource
  plugin :ressource_link, :service_id => SRV_APP

  unrestrict_primary_key()

  # Referential integrity
  one_to_many :application_etablissement
  one_to_many :param_application
  one_to_one :application_key

  def before_destroy
    application_key_dataset.destroy()
    super
  end
  # Not nullable cols and unicity validation
  def validate
    super
  end
  
  def add_parameter(code, type_param_id, preference = 0, description = "", valeur_defaut = nil, autres_valeurs= nil)
    param = ParamApplication[:code => code, :application_id => self.id]
    if param 
      param.destroy
    end
  
    param = ParamApplication.create(:code => code, :application_id => self.id, :type_param_id => type_param_id, :preference => preference,
              :description => description, :valeur_defaut => valeur_defaut, :autres_valeurs => autres_valeurs)
  end

  def before_destroy
    param_application_dataset.destroy()
    super
  end
end

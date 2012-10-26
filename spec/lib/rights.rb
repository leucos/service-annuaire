#coding: utf-8
require_relative '../helper'

describe Rights do
  def create_admin_etb(r)
    u = create_test_user("test_admin")
    RoleUser.unrestrict_primary_key()
    RoleUser.create(:user_id => u.id, :ressource_id => r.id, :ressource_service_id => r.service_id, :role_id => ROL_ADM_ETB, :actif => true)

    return u
  end

  #in case something went wrong
  delete_test_ressources_tree()
  
  it "return create rights for user in ressource etablissement if user is admin" do
    ressource_etab = create_test_ressources_tree()
    admin = create_admin_etb(ressource_etab)
    Rights::get_rights(admin.id, SRV_SERVICE, SRV_USER).should == ["create_user"]
    delete_test_ressources_tree()
  end
end
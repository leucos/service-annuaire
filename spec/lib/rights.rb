#coding: utf-8
require_relative '../helper'

describe Rights do
  #in case something went wrong
  delete_test_ressources_tree()
  delete_test_role()
  delete_test_users()
  
  it "return create_user rights for user in ressource etablissement if user has role on etab" do
    r = create_test_role()
    ressource_etab = create_test_ressources_tree()
    # On créer un deuxième etab
    e2 = Etablissement.create(:nom => "test", :type_etablissement => TypeEtablissement.first)
    admin = create_user_with_role(r.id, ressource_etab)
    Rights.get_rights(admin.id, SRV_ETAB, ressource_etab.id, SRV_USER).should == [ACT_CREATE]
    Rights.get_rights(admin.id, SRV_ETAB, e2.id, SRV_USER).should == []
    delete_test_ressources_tree()
    delete_test_role()
  end

  it "return create_user rights for user in ressource etablissement if user has role on laclasse" do
    r = create_test_role()
    ressource_etab = create_test_ressources_tree()
    # On créer un deuxième etab
    e2 = Etablissement.create(:nom => "test", :type_etablissement => TypeEtablissement.first)
    admin = create_user_with_role(r.id)
    Rights.get_rights(admin.id, SRV_ETAB, ressource_etab.id, SRV_USER).should == [ACT_CREATE]
    Rights.get_rights(admin.id, SRV_ETAB, e2.id, SRV_USER).should == [ACT_CREATE]
    delete_test_ressources_tree()
    delete_test_role()
  end

  it "should return create rights for user on resource class if user has role on etab " do
    r = create_test_role()
    e = create_test_etablissement()
    admin = create_user_with_role(r.id, e.ressource)
    classe = e.add_regroupement({:type_regroupement_id => TYP_REG_CLS})
    Rights.get_rights(admin.id, SRV_CLASSE, classe.id).should == [ACT_DELETE]
    delete_test_ressources_tree()
    delete_test_role()
  end

  it "should handle merge similar rights" do
    # On donne des droits sur un établissement et sur laclasse
    r = create_test_role()
    e = create_test_etablissement()
    admin = create_user_with_role(r.id)
    RoleUser.create(:user_id => admin.id, 
      :ressource_id => e.ressource.id, :ressource_service_id => e.ressource.service_id,
      :role_id => r.id)
    Rights.get_rights(admin.id, SRV_ETAB, e.ressource.id, SRV_USER).should == [ACT_CREATE]
  end

  # it "should return create rights on service user for laclasse admin" do
  #   Rights.get_rights(admin.id, SRV_SERVICE, SRV_USER).should == [ACT_CREATE]
  # end

  # it "cumulate rights from different role" do
  #   # On donne un role d'admin d'établissement
  #   # Puis un role d'admin de groupe
  #   # On doit cumuler les role d'admin d'établissement et de groupe sur le groupe

  # end

  # todo : Tester que l'on puisse accéder aux fichiers d'un établissement mais pas à celui des classes
  # notion de service_parent_id
  
end
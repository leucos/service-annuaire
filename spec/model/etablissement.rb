#coding: utf-8
require_relative '../helper'

describe Etablissement do
  delete_test_etablissements()
  delete_test_application()
  delete_test_users()
  it "create and destroy a ressource on creation/deletion" do
    e = Etablissement.create(:type_etablissement => TypeEtablissement.first)
    Ressource[:service_id => SRV_ETAB, :id => e.id].should.not == nil
    e.destroy()
    Ressource[:service_id => SRV_ETAB, :id => e.id].should == nil
  end

  it "destroy param_etablissement on etablissement destruction" do
    a = create_test_application_with_param()
    e = create_test_etablissement()
    etab_id = e.id
    pref_id = a.param_application[1].id

    e.set_preference(pref_id, 200)
    delete_test_etablissements()
    ParamEtablissement.
      filter(:etablissement_id => etab_id, :param_application_id => pref_id).count.should == 0

    delete_test_application()
  end

  it "destroy profil_user on etablissement destruction" do
    e = create_test_etablissement()
    u = create_test_user()
    u.add_profil(e.id, PRF_ELV)
    e.destroy()
    ProfilUser.filter(:user => u).count.should == 0

    delete_test_etablissements()
    delete_test_users()
  end

  it "destroy role_user on etablissement destruction" do
    e = create_test_etablissement()
    u = create_test_user()
    RoleUser.create(:user => u, :ressource_id => e.id, :ressource_service_id => SRV_ETAB, :role_id => ROL_ELV_ETB)
    e.destroy()

    RoleUser.filter(:user => u).count.should == 0

    delete_test_etablissements()
    delete_test_users()
  end

  it "add a regroupement" do
    e = create_test_etablissement()
    e.add_regroupement({:type_regroupement_id => TYP_REG_CLS})
    Regroupement.filter(:etablissement => e).count.should == 1
    delete_test_etablissements()
  end

  it "destroy regroupement on etablissement destruction" do
    e = create_test_etablissement()
    etab_id = e.id
    e.add_regroupement({:type_regroupement_id => TYP_REG_CLS})
    delete_test_etablissements()
    Regroupement.filter(:etablissement_id => etab_id).count.should == 0    
  end

  it "add and remove application" do
    
  end

  it "destroy application_etablissement on etablissement destruction" do
  end

  it "add a regroupement" do

  end
end
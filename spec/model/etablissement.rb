#coding: utf-8
require_relative '../helper'

describe Etablissement do
  it "create and destroy a ressource on creation/deletion" do
    e = Etablissement.create(:type_etablissement => TypeEtablissement.first)
    Ressource[:service_id => SRV_ETAB, :id => e.id].should.not == nil
    e.destroy()
    Ressource[:service_id => SRV_ETAB, :id => e.id].should == nil
  end

  it "destroy param_etablissement on etablissement destruction" do
  end

  it "destroy profil_user on etablissement destruction" do
  end

  it "destroy role_user on etablissement destruction" do
  end

  it "destroy regroupement on etablissement destruction" do
  end

  it "destroy application_etablissement on etablissement destruction" do
  end
end
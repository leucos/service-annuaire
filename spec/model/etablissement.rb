#coding: utf-8
require_relative '../helper'

describe Etablissement do
  it "create and destroy a ressource on creation/deletion" do
    e = Etablissement.create(:type_etablissement => TypeEtablissement.first)
    Ressource[:service_id => SRV_ETAB, :id => e.id].should.not == nil
    e.destroy()
    Ressource[:service_id => SRV_ETAB, :id => e.id].should == nil
  end
end
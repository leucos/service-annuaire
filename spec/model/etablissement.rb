#coding: utf-8
require_relative '../helper'

describe Etablissement do
  it "create and destroy a ressource on creation/deletion" do
    e = Etablissement.create()
    Ressource[:service_id => "ETAB", :id_externe => e.id].should.not == nil
    e.destroy()
    Ressource[:service_id => "ETAB", :id_externe => e.id].should == nil
  end
end
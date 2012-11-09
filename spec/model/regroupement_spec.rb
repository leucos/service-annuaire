#coding: utf-8
require_relative '../helper'

describe Regroupement do
  Regroupement.filter(:libelle => "test").destroy()
  it "return the right ressource for classe, groupe and groupe libre with the good service_id" do
    classe = Regroupement.create(:type_regroupement_id => TYP_REG_CLS, :libelle => "test")
    groupe = Regroupement.create(:type_regroupement_id => TYP_REG_GRP, :libelle => "test")
    libre = Regroupement.create(:type_regroupement_id => TYP_REG_LBR, :libelle => "test")
    classe.ressource.id.should == classe.id.to_s
    classe.ressource.service_id.should == SRV_CLASSE
    groupe.ressource.id.should == groupe.id.to_s
    groupe.ressource.service_id.should == SRV_GROUPE
    libre.ressource.id.should == libre.id.to_s
    libre.ressource.service_id.should == SRV_LIBRE
    Regroupement.filter(:libelle => "test").destroy()
  end 
end
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
  end 

  it " adds a prof to  classe" do
    # create  a class 
    classe = Regroupement.create(:type_regroupement_id => TYP_REG_CLS, :libelle => "test")

    user = User.create(:login => "test", :nom => "test", :prenom => "test")
    # a list of matieres   
    matieres = [200, 400]  
    # add user_role
    classe.add_prof(user.id, matieres)

    RoleUser.include?(RoleUser[:user_id => user.id, :role_id =>"PROF_CLS"]).should == true 

  end 
end
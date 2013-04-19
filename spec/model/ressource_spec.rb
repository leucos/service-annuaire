#coding: utf-8
require_relative '../helper'

# create_test_ressources
#   e = Etablissement.create(:nom => "test", :type_etablissement => TypeEtablissement.first)
#   u1 = create_test_user_in_etab(e.id, "test")
#   u2 = create_test_user_in_etab(e.id, "test2")
# 
# end

describe Ressource do
  
  before(:each) do
    delete_test_users()
    delete_test_etablissements()
    #@test_ressource = create_test_ressources_tree()
    @e = create_test_etablissement()
    @u1 = create_test_user_in_etab(@e.id, "test1")
    @u2 = create_test_user_in_etab(@e.id, "test3")
  end

  after(:each) do
    delete_test_etablissements
    delete_test_users()
  end

  it ".children gives all the ressource children", :broken=>true do
    @test_ressource.children.length.should == 2
  end

  it ".destroy_children destroy well all the children", :broken=>true do
    @test_ressource.destroy_children()
    @test_ressource.children.length.should == 0
    # On s'assure que les données associées aux ressources sont bien supprimées aussi
    User.filter(:nom => "test", :prenom => 'test').count.should == 0
  end

  it ".parent give the ressource parent", :broken => true do
    @test_ressource.parent.should == Ressource[:service_id => SRV_LACLASSE]
  end

  it "all resources belongs to root (laclasse)" do
    root = Ressource.laclasse
    @e.ressource.belongs_to(root).should == true
    @u1.ressource.belongs_to(root).should == true 
  end 

  it "a user belongs to an etablissement in which he has a profil" do
    @u1.ressource.belongs_to(@e.ressource).should == true 
    u3 = create_test_user("test4")
    u3.ressource.belongs_to(@e.ressource).should == false
    # add u3 to @e 
    ProfilUser.create(:profil_id => "ELV", :user_id => u3.id, :etablissement_id => @e.id)
    u3.ressource.belongs_to(@e.ressource).should == true
    u3.destroy 
  end 

  it "a classe belongs to its etablissemnet" do
    test_classe = Regroupement.create(:libelle => "test class", :type_regroupement_id => "CLS", 
      :etablissement_id => @e.id,:code_mef_aaf => "00010001310")
    test_classe.ressource.belongs_to(@e.ressource).should == true
    @u1.ressource.belongs_to(test_classe.ressource).should == false 
    @u1.add_to_regroupement(test_classe.id)
    @u1.ressource.belongs_to(test_classe.ressource).should == true
    @u1.ressource.belongs_to(@e.ressource) == true
    test_classe.destroy
  end

  it "a user belongs to his class or group" do 
    test_classe = Regroupement.create(:libelle => "test class", :type_regroupement_id => "CLS", 
      :etablissement_id => @e.id,:code_mef_aaf => "00010001310")
    test_classe.ressource.belongs_to(@e.ressource).should == true
    @u1.ressource.belongs_to(test_classe.ressource).should == false 
    @u1.add_to_regroupement(test_classe.id)
    @u1.ressource.belongs_to(test_classe.ressource).should == true
    @u1.ressource.belongs_to(@e.ressource) == true
    test_classe.destroy  
  end

  it "a ressource belongs to itself" do 
    @e.ressource.belongs_to(@e.ressource).should == true
    @u1.ressource.belongs_to(@u1.ressource).should == true 
  end

  it "a parent belongs to classes, groupes of his children" do 
    p1 = create_test_user("parent")
    @u1.add_parent(p1)
    test_classe = Regroupement.create(:libelle => "test class", :type_regroupement_id => "CLS", 
      :etablissement_id => @e.id,:code_mef_aaf => "00010001310")
    test_classe.ressource.belongs_to(@e.ressource).should == true
    @u1.ressource.belongs_to(test_classe.ressource).should == false 
    p1.ressource.belongs_to(test_classe.ressource).should == false
    @u1.add_to_regroupement(test_classe.id)
    @u1.ressource.belongs_to(test_classe.ressource).should == true
    p1.ressource.belongs_to(test_classe.ressource).should == true
    test_classe.destroy
  end

end
#coding: utf-8
require_relative '../helper'

describe Ressource do
  # In case something went wrong
  delete_test_ressources_tree()
  test_ressource = create_test_ressources_tree()

  it ".children gives all the ressource children" do
    test_ressource.children.length.should == 2
  end

  it ".destroy_children destroy well all the children" do
    test_ressource.destroy_children()
    test_ressource.children.length.should == 0
    # On s'assure que les données associées aux ressources sont bien supprimées aussi
    User.filter(:nom => "test", :prenom => 'test').count.should == 0
  end

  it ".parent give the ressource parent" do
    test_ressource.parent.should == Ressource[:service_id => SRV_LACLASSE]
  end

  delete_test_ressources_tree()
end
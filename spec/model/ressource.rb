#coding: utf-8
require_relative '../helper'

describe Ressource do
  def create_test_user_in_etab(etb_id, login)
    u = create_test_user(login)
    # On assigne manuellement la ressource utilisateur à cet établissement
    r = Ressource[:id => u.id, :service_id => SRV_USER]
    r.parent_id = etb_id
    r.parent_service_id = SRV_ETAB
    r.save()
  end

  def create_test_ressources_tree
    e = Etablissement.create(:nom => "test", :type_etablissement => TypeEtablissement.first)
    create_test_user_in_etab(e.id, "test")
    create_test_user_in_etab(e.id, "test2")
    return Ressource[:id => e.id, :service_id => SRV_ETAB]
  end

  def delete_test_ressources_tree
    delete_test_users()
    Etablissement.filter(:nom => "test").destroy()
  end

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

  delete_test_ressources_tree()
end
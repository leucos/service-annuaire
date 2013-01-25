#coding: utf-8
require_relative '../../helper'
require_relative '../../oracle_helper'

describe "Import oracle" do
  #
  # Test des helpers
  #
  it "Créer un utilisateur de test et incremente l'uid" do
    u = Ora::create_user()
    puts "ID=#{u.id} UID_LDAP=#{u.uid_ldap}"

    Utilisateur.filter(:uid_ldap => u.uid_ldap).count.should == 1
  end
  
  # it "importe un utilisateur simple sans problème" do

  # end
end
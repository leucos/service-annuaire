#coding: utf-8
require_relative '../../../helper'


# Classe qui permet de récupérer une base de donnée en mémoire initialisée
# avec toutes les tables concernées par l'alimentation
class DbInitializer < Alimentation::ParserXmlMenesr
  attr_reader :cur_etb_data
  def initialize
    init_memory_db()
  end
end

# Classe qui va nous permettre de spécifier des fausses données de parsing
# Pour pouvoir tester les différentes diff générées
class DiffTest < Alimentation::DiffGenerator
  attr_reader :cur_etb_data, :cur_etb_diff
end

describe Alimentation::DiffGenerator do
  before :each do
    p = DbInitializer.new
    @diff_gen = DiffTest.new("0666699Z", p.cur_etb_data, true)
  end

  it "Trouve le bon prochain login même s'il y a déjà une personne qui va être créée avec ce login" do
    create_test_user("gcharpak")
    
    user = @diff_gen.cur_etb_data[:user].find_or_add({:nom => "Charpak", :prenom => "Georges"})
    user[:login] = @diff_gen.find_available_login(user)
    user[:login].should == "gcharpak1"
    @diff_gen.find_available_login(user).should == "gcharpak2"
  end

  it "Clean bien les données avant l'update" do
    # On a rien a updater
    @diff_gen.clean_data_to_update({id: 1}, {id: 1}, [:id]).should == false
    data = {id: 1, nom: "test", prenom: "test"}
    db = {id: 1, nom: "testa", prenom: "test"}
    @diff_gen.clean_data_to_update(data, db, [:id]).should == true
    data.keys.include?(:nom).should == true
    data[:nom].should == "test"
    # L'id est toujours gardé car on en a besoin pour l'update
    data.keys.include?(:id).should == true
    # En revanche, le prenom n'est pas mis à jour
    data.keys.include?(:prenom).should == false
    
    data = {id: 1, nom: "test", prenom: "test"}
    @diff_gen.clean_data_to_update(data, db, [:id, :prenom]).should == true
    # Sauf s'il considéré comme Primary key
    data.keys.include?(:prenom).should == true
    expect{
        @diff_gen.clean_data_to_update({id: 1}, {id: 2}, [:id])
    }.to raise_error(Alimentation::MismatchUpdateIdError)
    expect{
      @diff_gen.clean_data_to_update({id: 1, plop: 1}, {id: 2, plop: 1}, [:id, :plop])
    }.to raise_error(Alimentation::MismatchUpdateIdError)
    expect{
      @diff_gen.clean_data_to_update({nom: "test"}, {nom: "test"}, [:id])  
    }.to raise_error(Alimentation::NoIdError)
    
  end

  it "add_data ajoute bien les données à inserer/modifier/détruire dans la BDD" do
    @diff_gen.add_data(:user, :create, {nom: "test"})
    @diff_gen.cur_etb_diff[:user][:create].count.should == 1
    expect{
      @diff_gen.add_data(:user, :update, {nom: "test"})
    }.to raise_error(Alimentation::NoDbEntryError)
    expect{
      @diff_gen.add_data(:truc, :create, {nom: "test"})
    }.to raise_error(Alimentation::WrongTableError)

    @diff_gen.add_data_to_update(:user, {id: 1, nom: "test"}, {id: 1, nom: "test"})
    puts @diff_gen.cur_etb_diff[:user][:update]
    @diff_gen.cur_etb_diff[:user][:update].count.should == 0

    @diff_gen.add_data_to_update(:user, {id:1, nom: "test_modifié"}, {id: 1, nom: "test"})
    @diff_gen.cur_etb_diff[:user][:update].count.should == 1
  end

  it "Gère les diff d'établissement" do
    @diff_gen.diff_etablissement({code_uai: "TEST", :nom => "test"})
    @diff_gen.cur_etb_diff[:etablissement][:create].count.should == 1
    e = create_test_etablissement()
    e.update(:code_uai => "TEST2")
    @diff_gen.diff_etablissement({code_uai: "TEST2", :nom => "test2"})
    @diff_gen.cur_etb_diff[:etablissement][:update].count.should == 1
  end
end
#coding: utf-8
require_relative '../../../helper'

# Classe qui initialise les données qui vont bien pour les tests
class AlimentorTest < Alimentation::Alimentor 
  def initialize
    datasource = "../../../fixture/Complet69-TS.20100425.tgz"
    prepare_alimentation()
  end 

end

def time(label)
  t1 = Time.now
  yield.tap{ puts "%s: %.1fs" % [ label, Time.now-t1 ] }
end

#def count_requests(label)
  #count = 0 
  #yield.tap
#end 

# we must create a Test Data Sources
# modify some data
describe Alimentation::Alimentor do
  before(:all) do
    # Data_SOURCE is a test data source  that contains files for two etablissements
    Data_SOURCE = "/home/bashar/rubyProjects/service-annuaire/service-annuaire/spec/fixture/Complet69-ENTTSSERVICES.20130218.tgz"
    @al = Alimentation::Alimentor.new(Data_SOURCE)
    @al.prepare_alimentation
  end
  
  it "should accept a good datasource" do
    @al.archive_name.should == Data_SOURCE
    @al.date_alim.should ==  Date.parse('20130218')
  end
=begin
  it "should prepare the alimentation " do
    al = Alimentation::Alimentor.new(Data_SOURCE)
    al.prepare_alimentation.should == true
  end

  it "should parse and detect errors for all xml files clasified by etablissement" do
    #one problem what do we need to test
    time("parsing all etabs") do 
      @al.parse_all_etb
    end
  end
=end   
  it "should parse and detect errors for a specific etablissement" do
    @al.parse_etb("0690078K")
    puts "------------------\n"
    puts "users = #{@al.parser.db.collection('users').count}"
    puts "etablissements = #{@al.parser.db.collection('etablissement').count}" 
    puts "regroupements = #{@al.parser.db.collection('regroupement').count}"
    puts "------------------\n"
    pp @al.parser.db.collection("error").find.to_a
    
    puts "------------------\n"
    @al.parse_etb("0693890D")
    puts "------------------\n"
    puts "users = #{@al.parser.db.collection('users').count}"
    puts "etablissements = #{@al.parser.db.collection('etablissement').count}" 
    puts "regroupements = #{@al.parser.db.collection('regroupement').count}"
    puts "------------------\n"
    pp @al.parser.db.collection("error").find.to_a    
  end



  it "should also return statistics after the operation" do 
    
  end 
end 
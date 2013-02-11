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

describe Alimentation::Alimentor do

  Data_SOURCE = "/home/bashar/rubyProjects/service-annuaire/service-annuaire/spec/fixture/Complet69-TS.20120425.tgz"

  it "should accept a good datasource" do
    al = Alimentation::Alimentor.new(Data_SOURCE)
    al.archive_name.should == Data_SOURCE
    al.date_alim.should ==  Date.parse('20120425')
    #puts al.inspect
  end

  it "should prepare the alimentation " do
    al = Alimentation::Alimentor.new(Data_SOURCE)
    al.prepare_alimentation.should == true
  end

  it "should parse and detect errors in xml files" do
    al = Alimentation::Alimentor.new(Data_SOURCE)
    al.prepare_alimentation
    time("parsing all etabs") do 
      al.parse_all_etb
    end
  end

=begin
  it "should parse data by categorie EtabEducNat and generate a valid number of records" do 
    # parsing file using alimentor
    datasource = "/home/bashar/rubyProjects/service-annuaire/service-annuaire/spec/fixture/full.tar.gz"
    al = Alimentation::Alimentor.new(datasource)
    al.prepare_data
    parsed_etab = al.parse_categorie("EtabEducNat")
    #puts parsed_etab[:etablissement].length

    #read data using xml parser
    xmlfeed = Nokogiri::XML(open("tmp/FULL_ENTTSSERVICES_Complet_20130117_EtabEducNat_0000.xml"))
    all_etabs = xmlfeed.xpath("//addRequest")
    #puts all_items.count

    # the tow parsers must generate the same number of records(etablissement)
    parsed_etab[:etablissement].length.should == all_etabs.count 

  end

  it "should parse all data in the tgz file starting with EtabEducNat" do
    datasource = "/home/bashar/rubyProjects/service-annuaire/service-annuaire/spec/fixture/full.tar.gz"
    al = Alimentation::Alimentor.new(datasource)
    al.prepare_data
    al.parse_data
  end

  it "should also return statistics after the operation" do 
    
  end
=end  
end 
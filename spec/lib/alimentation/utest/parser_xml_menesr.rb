#coding: utf-8
require_relative '../../../helper'

# Classe qui initialise les données qui vont bien pour les tests
class ParserTest < Alimentation::ParserXmlMenesr
  def initialize
    init_memory_db()
    @cur_etb_uai = '0690000X'
    @cur_etb_xml_id = 1234
    @cur_etb = @cur_etb_data[:etablissement].find_or_add({:code_uai => @cur_etb_uai})
  end
end

# Renvois la description XML d'un élève
def get_eleve_xml
  Nokogiri::XML('<addRequest>
<operationalAttributes><attr name="categoriePersonne"><value>Eleve</value></attr></operationalAttributes>
<identifier><id>748220</id></identifier>
<attributes>
<attr name="ENTPersonJointure"><value>123456</value></attr>
<attr name="ENTPersonDateNaissance"><value>06/06/1996</value></attr>
<attr name="ENTPersonNomPatro"><value>RODRIGUEZ</value></attr>
<attr name="sn"><value>RODRIGUEZ</value></attr>
<attr name="givenName"><value>Michèle</value></attr>
<attr name="ENTPersonAutresPrenoms"><value>Michèle</value><value>Robert</value></attr>
<attr name="personalTitle"><value>Mlle</value></attr>
<attr name="ENTEleveParents"><value>123457</value><value>123458</value></attr>
<attr name="ENTElevePere"><value>123457</value></attr>
<attr name="ENTEleveMere"><value>123458</value></attr>
<attr name="ENTEleveAutoriteParentale"><value>123457</value><value>123458</value></attr>
<attr name="ENTElevePersRelEleve1"><value>123459</value></attr>
<attr name="ENTEleveQualitePersRelEleve1"><value>CONTACT</value></attr>
<attr name="ENTElevePersRelEleve2"><value>123460</value></attr>
<attr name="ENTEleveQualitePersRelEleve2"><value>CONTACT</value></attr>
<attr name="ENTEleveBoursier"><value>N</value></attr>
<attr name="ENTEleveRegime"><value>EXTERNE LIBRE</value></attr>
<attr name="ENTEleveTransport"><value>N</value></attr>
<attr name="ENTEleveStatutEleve"><value>SCOLAIRE</value></attr>
<attr name="ENTEleveMEF"><value>10210001110</value></attr>
<attr name="ENTEleveLibelleMEF"><value>4EME</value></attr>
<attr name="ENTEleveNivFormation"><value>4EME GENERALE (N.C 4E AES)</value></attr>
<attr name="ENTEleveFiliere"><value>4EME GENERALE (N.C 4E AES)</value></attr>
<attr name="ENTEleveEnseignements"><value>ANGLAIS LV1</value><value>ARTS PLASTIQUES</value><value>EDUCATION CIVIQUE</value><value>EDUCATION MUSICALE</value><value>EDUCATION PHYSIQUE ET SPORTIVE</value><value>ESPAGNOL LV2</value><value>FRANCAIS</value><value>HISTOIRE ET GEOGRAPHIE</value><value>ITINERAIRE DECOUVERTE (ARTS HUMANITE)</value><value>ITINERAIRE DECOUVERTE (AUTRES)</value><value>ITINERAIRE DECOUVERTE (CREATION TECHNIQ)</value><value>ITINERAIRE DECOUVERTE (LANGUES CIVILIS.)</value><value>ITINERAIRE DECOUVERTE (NATURE CORPS HUM)</value><value>MATHEMATIQUES</value><value>PHYSIQUE-CHIMIE</value><value>SCIENCES DE LA VIE ET DE LA TERRE</value><value>TECHNOLOGIE</value><value>VIE SCOLAIRE</value></attr>
<attr name="ENTPersonStructRattach"><value>1234</value></attr>
<attr name="ENTEleveClasses"><value>1234$4E3</value></attr>
<attr name="ENTEleveGroupes"><value/></attr>
</attributes>
</addRequest>').css("addRequest, modifyRequest").first
end

describe Alimentation::ParserXmlMenesr do
  it "parse well an eleve user" do
    p = ParserTest.new
    eleve = p.parse_user(get_eleve_xml, 'Eleve', 'ELV')
    eleve.should.not == nil
    eleve[:prenom].should == "Michèle"
    eleve[:sexe].should == 'F'
    eleve[:nom].should == 'RODRIGUEZ'
    eleve[:id_jointure_aaf].should == 123456
  end
end

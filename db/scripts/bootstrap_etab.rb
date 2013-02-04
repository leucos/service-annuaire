#coding: utf-8
require_relative "../../app"

# Code temporaire pour remplir la base des établissement avec les données d'oracle

# Correspondance des type id
# 
def get_type_etablissement_id(oracle_id)
  table_correspondance_id = {
    13 => ["école", "privé"],
    14 => ["école", "public"],
    15 => ["collège", "privé"],
    16 => ["collège", "public"],
    17 => ["lycée", "privé"],
    18 => ["lycée", "public"],
    19 => ["batiment", "public"],
    20 => ["lycée professionnel", "public"],
    21 => ["maison familiale rurale", "public"],
    22 => ["campus", "public"],
    23 => ["CG Jeunes", "public"],
    24 => ["crdp", "public"],
    25 => ["Cité scolaire", "public"],
    26 => ["Cité scolaire", "privé"],
    27 => ["lycée professionnel", "privé"]
  }

  contrat = table_correspondance_id[oracle_id][1] == "public" ? "PU" : "PR" 
  type = TypeEtablissement.filter(:nom.ilike(table_correspondance_id[oracle_id][0]), :type_contrat => contrat).first
  return type.nil? ? TypeEtablissement.first.id : type.id
end


EtablissementOracle.each do |e|
  type_id = get_type_etablissement_id(e.tpe_id)
  Etablissement.create(:nom => e.nom, :adresse => e.adr,:code_uai => e.code_rne, 
    :longitude => e.longitude, :latitude => e.latitude,
    :telephone => e.tel, :fax => e.fax, :code_postal => e.cp, :type_etablissement_id => type_id)
end
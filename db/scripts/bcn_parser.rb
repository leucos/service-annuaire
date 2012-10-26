#!ruby
#coding: utf-8

require "csv"

require_relative "../../config/database"

def bootstrap_matiere
  puts "Truncate matiere_enseignee and famille_matiere table"
  DB[:matiere_enseignee].truncate()
  DB[:famille_matiere].truncate()
  #C'est le CSV qui va nous donner les id
  first = true
  puts "parse n_famille_matiere_BCN.csv"
  #Petit script qui va parser les fichiers csv de la BCN (Base Centrale des Nommenclature) pour remplir les tables liées au matières
  CSV.foreach("db/data/n_famille_matiere_BCN.csv") do |row|
    unless first
      fm = DB[:famille_matiere].insert(:id => row[0], :libelle_court => row[1], :libelle_long => row[2])
    end
    first = false if first
  end

  puts "parse n_matiere_enseignee_BCN.csv"
  first = true
  CSV.foreach("db/data/n_matiere_enseignee_BCN.csv") do |row|
    unless first
      f = DB[:matiere_enseignee].insert(:id => row[0], :famille_matiere_id => row[1],
        :libelle_court => row[2], :libelle_long => row[3], :libelle_edition => row[4])
    end
    first = false if first
  end
end
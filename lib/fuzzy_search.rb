#coding: utf-8
module Sequel
  module Plugins
    # Tentative de faire simplement de la recherche multi champs sur un model Sequel
    module FuzzySearch

      module DatasetMethods
        # Rajoute une fonction search au model et au dataset
        # param fields Array<:fields> liste des champs sur lesquels faire la recherche (ex : [:nom, :prenom, :login])
        # param patterns Array<String> liste des chaines à rechercher (ex : ["Charpack", "Georges"])
        def search(fields, patterns)
          dataset = self
          patterns.each do |p|
            or_expression = []
            fields.each {|f| or_expression.push([f.ilike("%#{p}%"), true])}
            dataset = dataset.filter(Sequel.or(or_expression))
          end

          return dataset
        end
      end

      module ClassMethods
        def search(fields, patterns)
          self.dataset.search(fields, patterns)
        end
      end
    end
  end
end
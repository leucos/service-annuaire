#coding: utf-8
module Sequel
  module Plugins
    # Tentative de faire simplement de la recherche multi champs sur un model Sequel
    module FuzzySearch

      module DatasetMethods
        # Rajoute une fonction Search au model
        # param fields Array<:fields>
        # param patterns Array<String>
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
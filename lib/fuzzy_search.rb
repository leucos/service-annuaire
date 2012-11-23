#coding: utf-8
module Sequel
  module Plugins
    # Tentative de faire simplement de la recherche multi champs sur un model Sequel
    module FuzzySearch
      module ClassMethods
        # Rajoute une fonction Search au model
        # param fields Array<:fields>
        # param patterns Array<String>
        def search(fields, patterns)
          dataset = self
          patterns.each do |p|
            dataset = dataset.filter(Sequel.join(fields).ilike("%#{p}%"))
          end

          return dataset
        end
      end
    end
  end
end